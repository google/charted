//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///Function callback to filter items in the input
typedef bool AggregationFilterFunc(var item);

typedef int CompareFunc(dynamic a, dynamic b);

typedef dynamic FieldAccessor(dynamic item, dynamic key);

/// Given list of items, dimensions and facts, compute
/// aggregates (COUNT, SUM, MIN, MAX) for facts at each dimension level.
class AggregationModel {
  // Number of aggregations we collect on each fact
  int _aggregationTypesCount = 0;

  // Currently supported list of aggregations.
  static final List<String> supportedAggregationTypes = [
    'sum',
    'min',
    'max',
    'valid'
  ];

  // Computed aggregation types.
  List<String> computedAggregationTypes;

  // Offsets of aggregations that are computed once per fact per dimension
  // If an offset is null, it will not be computed
  int _offsetSum;
  int _offsetMin;
  int _offsetMax;
  int _offsetCnt;

  // Offset of aggregations that one computed once per dimension
  int _offsetFilteredCount;
  int _offsetSortedIndex;

  // Number of bits we can use in an integer without making it medium int
  static const int SMI_BITS = 30;

  // Computed aggregations
  static const int AGGREGATIONS_BUFFER_LENGTH = 1024 * 1024;
  Float64List _aggregations;

  // Cache of fact values
  Float64List _factsCache;

  // Cache of enumerated dimensions
  List<int> _dimEnumCache;

  // Sorted list of indices (for data in _rows/_dimEnumCache/_factsCache)
  List<int> _sorted;

  // Enumeration map for dimension values
  List<Map<dynamic, int>> _dimToIntMap;

  // Sort orders for dimension values
  List<List<int>> _dimSortOrders;

  // Input
  List _rows;
  List _dimFields;
  List _factFields;

  // When groupBy is called, this value represents the
  // common prefix of the old and new dimensions list.
  int _dimPrefixLength = 0;

  // Dimensions mapped to computed aggregates
  Map<String, int> _dimToAggrMap;

  // null when no filter was applied.
  // Otherwise, store a bitmap indicating if an item was included.
  List<int> _filterResults;

  // Cache of entities created for the facts on this aggregation view.
  Map<String, AggregationItem> _entityCache;

  // List of field names that aggregation items will have.
  List<String> _itemFieldNamesCache;

  // Walk through the map, by splitting key at '.'
  final bool walkThroughMap;

  // Map of fieldName to comparator function.
  final Map<String, CompareFunc> comparators;

  // Timing operations
  static final Logger _logger = new Logger('aggregations');
  Stopwatch _timeItWatch;
  String _timeItName;

  FieldAccessor dimensionAccessor;
  FieldAccessor factsAccessor;

  /// Create a new [AggregationModel] from a [collection] of items,
  /// list of [dimensions] on which the items are grouped and a list of [facts]
  /// on which aggregations are computed.
  AggregationModel(Iterable collection, List dimensions, List facts,
      {List<String> aggregationTypes,
      this.walkThroughMap: false,
      this.comparators: const <String, CompareFunc>{},
      this.dimensionAccessor,
      this.factsAccessor}) {
    _init(collection, dimensions, facts, aggregationTypes);
  }

  void _timeItStart(String name) {
    _timeItName = name;
    _timeItWatch = new Stopwatch();
    _timeItWatch.start();
  }

  void _timeItEnd() {
    _timeItWatch.stop();
    _logger.info('[aggregations/$_timeItName] '
        '${_timeItWatch.elapsed.inMilliseconds}ms/${_rows.length}r');
  }

  List get factFields => _factFields;
  List get dimensionFields => _dimFields;

  /// Initialize the view
  void _init(Iterable collection, List dimensions, List facts,
      List<String> aggregationTypes) {
    if (collection == null) {
      throw new ArgumentError('Data cannot be empty or null');
    }

    if (facts == null || facts.isEmpty) {
      throw new ArgumentError('Facts cannot be empty or null');
    }

    if (dimensions == null) {
      dimensions = [];
    }

    if (dimensionAccessor == null) {
      dimensionAccessor = _fetch;
    }

    if (factsAccessor == null) {
      factsAccessor = _fetch;
    }

    if (aggregationTypes != null) {
      Iterable unknownAggregationTypes =
          aggregationTypes.where((e) => !supportedAggregationTypes.contains(e));
      if (unknownAggregationTypes.length != 0) {
        throw new ArgumentError(
            'Unknown aggregation types: ${unknownAggregationTypes.join(', ')}');
      }
    } else {
      aggregationTypes = ['sum'];
    }

    // Always adding 'count' for correct computation of average and count.
    if (!aggregationTypes.contains('valid')) {
      aggregationTypes.add('valid');
    }

    _rows = new List.from(collection, growable: false);
    _dimFields = new List.from(dimensions, growable: false);
    _factFields = new List.from(facts, growable: false);
    _entityCache = new Map<String, AggregationItem>();

    _createBuffers();

    _aggregationTypesCount = aggregationTypes.length;
    for (int i = 0; i < _aggregationTypesCount; i++) {
      switch (aggregationTypes[i]) {
        case 'sum':
          _offsetSum = i;
          break;
        case 'min':
          _offsetMin = i;
          break;
        case 'max':
          _offsetMax = i;
          break;
        case 'valid':
          _offsetCnt = i;
          break;
      }
    }
    computedAggregationTypes = new List.from(aggregationTypes, growable: false);

    // Preprocess the data
    _preprocess();
  }

  /// Re-calculate aggregations based on new dimensions.
  void groupBy(List dimensions, [AggregationFilterFunc filter = null]) {
    if (dimensions == null) {
      dimensions = [];
    }

    List savedDimFields = _dimFields;
    _dimFields = new List.from(dimensions, growable: false);

    _dimPrefixLength = 0;
    while (_dimPrefixLength < _dimFields.length &&
        _dimPrefixLength < savedDimFields.length &&
        savedDimFields[_dimPrefixLength] == _dimFields[_dimPrefixLength]) {
      ++_dimPrefixLength;
    }

    _createBuffers();
    _preprocess(groupBy: true);

    // For groupBy, compute immediately.
    compute(filter);

    // Ensure that cache represents updated dimensions
    _updateCachedEntities();
  }

  /// Create buffers.
  ///
  /// This method is called when the object is being created and when
  /// a groupBy is called to change the dimensions on which
  /// aggregations are computed.
  void _createBuffers() {
    // Create both when object is created and groupBy is called
    _dimEnumCache = new Int32List(_dimFields.length * _rows.length);

    // Create only when the object is created
    if (_factsCache == null) {
      _factsCache = new Float64List((_factFields.length + 1) * _rows.length);
    }

    // Create only when the object is created
    if (_filterResults == null) {
      _filterResults = new List<int>((_rows.length) ~/ SMI_BITS + 1);
    }

    // Create both when object is created and groupBy is called
    // Reuse dimension enumerations if possible.
    var oldDimToInt = _dimToIntMap;
    _dimToIntMap = new List<Map<dynamic, int>>.generate(_dimFields.length,
        (i) => i < _dimPrefixLength ? oldDimToInt[i] : new Map<dynamic, int>());
  }

  /// Check cache entries
  /// When data is grouped by a new dimensions, entities that were
  /// created prior to the groupBy should be cleared and removed from cache
  /// if they aren't valid anymore.
  /// Update the entities that are valid after the groupBy.
  void _updateCachedEntities() {
    List keys = new List.from(_entityCache.keys, growable: false);
    keys.forEach((key) {
      _AggregationItemImpl entity = _entityCache[key];
      if (entity == null) {
        _entityCache.remove(key);
      } else if (entity != null && entity.isValid) {
        if (key.split(':').length <= _dimPrefixLength) {
          entity.update();
        } else {
          _entityCache.remove(key);
          entity.clear();
        }
      }
    });
  }

  final Map<String, List> _parsedKeys = {};

  /// Get value from a map-like object
  dynamic _fetch(var item, String key) {
    if (walkThroughMap && key.contains('.')) {
      return walk(item, key, _parsedKeys);
    } else {
      return item[key];
    }
  }

  /// Preprocess Data
  ///  - Enumerate dimension values
  ///  - Create sort orders for dimension values
  ///  - Cache facts in lists
  void _preprocess({bool groupBy: false}) {
    _timeItStart('preprocess');

    // Enumerate dimensions...
    // Cache dimensions and facts.

    List<int> dimensionValCount =
        new List<int>.generate(_dimFields.length, (idx) => 0);

    int dimensionsCount = _dimFields.length;
    int factsCount = _factFields.length;
    int rowCount = _rows.length;

    for (int ri = 0, factsDataOffset = 0, dimDataOffset = 0;
        ri < rowCount;
        ++ri, factsDataOffset += factsCount, dimDataOffset += dimensionsCount) {
      var item = _rows[ri];

      // Cache the fact values in the big buffer, but only
      // when we are initializing (not when a groupBy was called
      // after initialization)
      if (!groupBy) {
        for (int fi = 0; fi < factsCount; fi++) {
          var value = factsAccessor(item, _factFields[fi]);
          _factsCache[factsDataOffset + fi] =
              (value == null) ? double.NAN : value.toDouble();
        }
      }

      // Enumerate the dimension values and cache enumerated rows
      for (int di = 0; di < dimensionsCount; di++) {
        var dimensionVal = dimensionAccessor(item, _dimFields[di]);
        int dimensionValEnum = _dimToIntMap[di][dimensionVal];
        if (dimensionValEnum == null) {
          _dimToIntMap[di][dimensionVal] = dimensionValCount[di];
          dimensionValEnum = dimensionValCount[di]++;
        }
        _dimEnumCache[dimDataOffset + di] = dimensionValEnum;
      }
    }

    // Sort all dimensions internally
    // The resulting arrays would be used to sort the entire data

    List<List<int>> oldSortOrders = _dimSortOrders;
    _dimSortOrders = new List.generate(dimensionsCount, (i) {
      if (groupBy && i < _dimPrefixLength) {
        return oldSortOrders[i];
      }

      List dimensionVals = new List.from(_dimToIntMap[i].keys);
      List<int> retval = new List<int>(_dimToIntMap[i].length);

      // When a comparator is not specified, our implementation of the
      // comparator tries to gracefully handle null values.
      if (comparators.containsKey(_dimFields[i])) {
        dimensionVals.sort(comparators[_dimFields[i]]);
      } else {
        dimensionVals.sort(_defaultDimComparator);
      }

      for (int si = 0; si < retval.length; ++si) {
        retval[_dimToIntMap[i][dimensionVals[si]]] = si;
      }
      return retval;
    }, growable: false);

    // Create a list of sorted indices - only if we are not having a full
    // overlap of dimensionFields.
    if (!groupBy || _dimPrefixLength != _dimFields.length) {
      _sorted = new List<int>.generate(_rows.length, (i) => i, growable: false);
      _sorted.sort(_comparator);
    }

    // Pre-compute frequently used values
    _offsetSortedIndex = factsCount * _aggregationTypesCount;
    _offsetFilteredCount = factsCount * _aggregationTypesCount + 1;

    _timeItEnd();
  }

  // Ensures that null dimension values don't cause an issue with sorting
  int _defaultDimComparator(Comparable left, Comparable right) =>
      (left == null && right == null)
          ? 0
          : (left == null) ? -1 : (right == null) ? 1 : left.compareTo(right);

  /// Given item indices in rows, compare them based
  /// on the sort orders created while pre-processing data.
  int _comparator(int one, int two) {
    if (one == two) {
      return 0;
    }

    int offsetOne = _dimFields.length * one;
    int offsetTwo = _dimFields.length * two;

    for (int i = 0; i < _dimFields.length; ++i) {
      int diff = _dimSortOrders[i][_dimEnumCache[offsetOne + i]] -
          _dimSortOrders[i][_dimEnumCache[offsetTwo + i]];
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }

  /// Compute aggregations
  /// If [filter] is not null, it would be used to filter out items that
  /// should not be included in the aggregates.
  void compute([AggregationFilterFunc filter = null]) {
    _timeItStart('compute');

    _dimToAggrMap = new Map<String, int>();
    _aggregations = new Float64List(AGGREGATIONS_BUFFER_LENGTH);
    _filterResults = filter == null
        ? null
        : new List<int>.filled((_rows.length ~/ SMI_BITS) + 1, 0);

    int rowCount = _rows.length;
    int dimensionCount = _dimFields.length;
    int factsCount = _factFields.length;

    // Saves current dimension value to which we are aggregating
    // Values of dimensions are in even indices (starting at 0) and
    // location of respective dimension in buffer is in odd indices.
    List<int> currentDim = new List<int>(dimensionCount * 2);
    bool reset = true;
    bool isNewDimension = false;
    int aggregationSizePerDim = factsCount * _aggregationTypesCount;

    // Reserve the 0th position for top-level aggregations.
    int currentBufferPos = (factsCount * _aggregationTypesCount + 2);
    _dimToAggrMap[''] = 0;
    _aggregations[_offsetSortedIndex] = 0.0;

    for (int ri = 0, index = 0, dimensionDataOffset = 0, factsDataOffset = 0;
        ri < rowCount;
        ++ri, reset = false) {
      // If filter is not null, check if this row must be included in
      // the aggregations and mark it accordingly.
      index = _sorted[ri];
      if (filter != null) {
        if (!filter(_rows[index])) {
          continue;
        } else {
          _filterResults[ri ~/ SMI_BITS] |= (1 << (ri % SMI_BITS));
        }
      }

      dimensionDataOffset = index * dimensionCount;
      factsDataOffset = index * factsCount;

      // Update top-level aggregations.
      _updateAggregationsAt(0, factsDataOffset, ri == 0 ? true : false);

      // See which dimensions get effected by this row.
      // di => the index of the dimension
      // ci => index of the cached value in [currentDim]
      for (int di = 0, ci = 0; di < dimensionCount; ++di, ci += 2) {
        // If a dimension value changed, then all dimensions that are lower
        // in the hierarchy change too.
        if (reset ||
            currentDim[ci] != _dimEnumCache[dimensionDataOffset + di]) {
          currentDim[ci] = _dimEnumCache[dimensionDataOffset + di];
          currentDim[ci + 1] = currentBufferPos;

          // Save location to aggregations position in the buffer
          _dimToAggrMap[new List.generate(di + 1, (i) => currentDim[2 * i])
              .join(':')] = currentBufferPos;

          // Store items start position
          _aggregations[currentBufferPos + _offsetSortedIndex] = ri.toDouble();

          // After the aggregated values, we save the filtered count,
          // index of the first item (in sorted)
          currentBufferPos += (aggregationSizePerDim + 2);
          reset = true;
          isNewDimension = true;
        }

        _updateAggregationsAt(
            currentDim[ci + 1], factsDataOffset, isNewDimension);
        isNewDimension = false;
      }
    }

    _timeItEnd();
  }

  /// Helper function that does the actual aggregations.
  /// This function is called once per row per dimension.
  _updateAggregationsAt(
      int aggrDataOffset, int factsDataOffset, bool isNewDimension) {
    // Update count.
    _aggregations[aggrDataOffset + _offsetFilteredCount] += 1;

    // Update aggregation for each of the facts.
    for (int fi = 0, bufferFactOffset = aggrDataOffset;
        fi < _factFields.length;
        bufferFactOffset += _aggregationTypesCount, ++fi) {
      double factValue = _factsCache[factsDataOffset + fi];
      if (factValue.isNaN) {
        continue;
      }

      // Sum
      if (_offsetSum != null) {
        _aggregations[bufferFactOffset + _offsetSum] += factValue;
      }

      // Min
      if (_offsetMin != null &&
          (isNewDimension ||
              factValue < _aggregations[bufferFactOffset + _offsetMin])) {
        _aggregations[bufferFactOffset + _offsetMin] = factValue;
      }

      // Max
      if (_offsetMax != null &&
          (isNewDimension ||
              factValue > _aggregations[bufferFactOffset + _offsetMax])) {
        _aggregations[bufferFactOffset + _offsetMax] = factValue;
      }

      // Count
      if (_offsetCnt != null) {
        _aggregations[bufferFactOffset + _offsetCnt]++;
      }
    }
  }

  // TODO(prsd):
  // 1. Implementation of updates and posting updates to entities.
  //    patchEntity and addToEntity must add listeners on AggregationItems
  //    and any changes must be propagated to entities.
  // 2. Updates (add/remove/update) should do their best to update the
  //    aggregations and then maybe do a delayed recomputation (sort etc;)

  /// Update an item.
  /// If aggregates were already computed, they are updated to reflect the
  /// new value and any observers are notified.
  void updateItem(dynamic item, String field) {
    throw new UnimplementedError();
  }

  /// Add a new item.
  /// If aggregates were already computed, they are updated to reflect
  /// values on the new item.
  void addItem(dynamic item) {
    throw new UnimplementedError();
  }

  /// Remove an existing item.
  /// If aggregates were already computed, they are updated to reflect
  /// facts on the removed item.
  void removeItem(dynamic item) {
    throw new UnimplementedError();
  }

  /// Return an [AggregationItem] that represents facts for dimension
  /// represented by [dimension] Only one instance of an entity is created
  /// per dimension (even if this function is called multiple times)
  ///
  /// Callers of this method can observe the returned entity for updates to
  /// aggregations caused by changes to filter or done through add, remove
  /// or modify of items in the collection.
  AggregationItem facts(List<String> dimension) {
    List<int> enumeratedList = new List<int>();
    for (int i = 0; i < dimension.length; ++i) {
      enumeratedList.add(_dimToIntMap[i][dimension[i]]);
    }

    String key = enumeratedList.join(':');
    AggregationItem item = _entityCache[key];

    if (item == null && _dimToAggrMap.containsKey(key)) {
      item = new _AggregationItemImpl(this, dimension, key);
      _entityCache[key] = item;
    }

    return item;
  }

  /// Return a list of values that are present for a dimension field.
  List valuesForDimension(dynamic dimensionFieldName) {
    int di = _dimFields.indexOf(dimensionFieldName);
    if (di < 0) {
      return null;
    }
    List values = new List.from(_dimToIntMap[di].keys);
    if (comparators.containsKey(dimensionFieldName)) {
      values.sort(comparators[dimensionFieldName]);
    } else {
      values.sort(_defaultDimComparator);
    }
    return values;
  }
}

/// Parse a path for nested map-like objects.
/// Caches the parsed key in the passed map.
///
/// Takes map keys of the format:
///     "list(key=val;val=m).another(state=good).state"
/// and outputs:
///     ["list", {"key": "val", "val": "m"},
///      "another", {"state": "good"}, "state"]
List _parseKey(String key, Map parsedKeysCache) {
  List parts = parsedKeysCache == null ? null : parsedKeysCache[key];
  if (parts == null && key != null) {
    parts = new List();
    if (key.contains(').')) {
      int start = 0;
      int cursor = 0;
      bool inParams = false;
      List matchKeyVals;
      Map listMatchingMap = {};

      while (cursor < key.length) {
        if (!inParams) {
          cursor = key.indexOf('(', start);
          if (cursor == -1) {
            parts.addAll(key.substring(start).split('.'));
            break;
          }
          parts.addAll(key.substring(start, cursor).split('.'));
          cursor++;
          start = cursor;
          inParams = true;
        } else {
          cursor = key.indexOf(')', start);
          if (cursor == -1) {
            throw new ArgumentError('Invalid field name: $key');
          }
          listMatchingMap.clear();
          matchKeyVals = key.substring(start, cursor).split(';');
          matchKeyVals.forEach((value) {
            List keyval = value.split('=');
            if (keyval.length != 2) {
              throw new ArgumentError('Invalid field name: ${key}');
            }
            listMatchingMap[keyval[0]] = keyval[1];
          });
          parts.add(listMatchingMap);
          cursor += 2;
          start = cursor;
          inParams = false;
        }
      }
    } else {
      parts = key.split('.');
    }
    if (parsedKeysCache != null) {
      parsedKeysCache[key] = parts;
    }
  }

  return parts;
}

/// Walk a map-like structure that could have list in the path.
///
/// Example:
///     Map testMap = {
///       "first": "firstval",
///       "list": [
///         { "val": "m",
///           "key": "val",
///           "another": [
///             { 'state': 'good' },
///             { 'state': 'bad' }
///           ]
///         },
///         { "val": "m", "key": "invalid" },
///         { "val": "o" }
///       ]
///     };
///
///  For the above map:
///     walk(testMap, "list(key=val;val=m).another(state=good).state");
///  outputs:
///     good
dynamic walk(initial, String key, Map parsedKeyCache) {
  List parts = _parseKey(key, parsedKeyCache);
  return parts.fold(initial, (current, part) {
    if (current == null) {
      return null;
    } else if (current is List && part is Map) {
      for (int i = 0; i < current.length; i++) {
        bool match = true;
        part.forEach((key, val) {
          if ((key.contains('.') &&
                  walk(part, key, parsedKeyCache).toString() != val) ||
              part[key] != val) {
            match = false;
          }
        });
        if (match) {
          return current[i];
        }
      }
    } else {
      return current[part];
    }
  });
}
