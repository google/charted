//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// AggregationItem is created by [AggregationModel] to make access to facts
/// observable. Users must use AggregationItem.isValid before trying to access
/// the aggregations.
abstract class AggregationItem extends Observable {
  /// List of dimension fields in effect
  List<String> dimensions;

  /// Check if this entity is valid.
  /// Currently the only case where an entity becomes invalid
  /// is when a groupBy is called on the model.
  bool get isValid;

  /// Fetch the fact from AggregationModel and return it
  /// Currently takes keys in the form of "sum(spend)", where sum is
  /// the aggregation type and spend is fact's field name.
  ///
  /// Currently, "sum", "count", "min", "max", "avg", "valid" and "avgOfValid"
  /// are supported as the operators.
  operator [](String key);

  /// List of lower aggregations.
  List<AggregationItem> lowerAggregations();

  /// Check if we support a given key.
  bool containsKey(String key);

  /// List of valid field names for this entity.
  /// It's the combined list of accessors for individual items, items in
  /// the next dimension and all possible facts defined on the view.
  Iterable<String> get fieldNames;
}

/// Implementation of AggregationItem
/// Instances of _AggregationItemImpl are created only by AggregationModel
class _AggregationItemImpl extends Observable implements AggregationItem {
  static final List<String> derivedAggregationTypes = ['count', 'avg'];

  AggregationModel model;
  List<String> dimensions;

  String _key;

  int _factsOffset;

  /// Currently entities are created only when they have valid aggregations
  _AggregationItemImpl(this.model, this.dimensions, this._key) {
    if (model == null) {
      throw new ArgumentError('Model cannot be null');
    }
    if (_key == null) {
      _key = '';
    }

    // facts + list of items + list of children (drilldown)
    _factsOffset = model._dimToAggrMap[_key];
  }

  /// _dimToAggrMap got updated on the model, update ourselves accordingly
  void update() {
    _factsOffset = model._dimToAggrMap[_key];
  }

  /// Mark this entity as invalid.
  void clear() {
    _factsOffset = null;
  }

  bool get isValid => _factsOffset != null;

  dynamic operator [](String key) {
    if (!isValid) {
      throw new StateError('Entity is not valid anymore');
    }

    int argPos = key.indexOf('(');
    if (argPos == -1) {
      return _nonAggregationMember(key);
    }

    String aggrFunc = key.substring(0, argPos);
    int aggrFuncIndex = model.computedAggregationTypes.indexOf(aggrFunc);
    if (aggrFuncIndex == -1 && !derivedAggregationTypes.contains(aggrFunc)) {
      throw new ArgumentError('Unknown aggregation method: ${aggrFunc}');
    }

    String factName = key.substring(argPos + 1, key.lastIndexOf(')'));
    int factIndex = model._factFields.indexOf(factName);

    // Try parsing int if every element in factFields is int.
    if (model._factFields.every((e) => e is int)) {
      factIndex = model._factFields.indexOf(int.parse(factName, onError: (e) {
        throw new ArgumentError('Type of factFields are int but factName' +
            'contains non int value');
      }));
    }
    if (factIndex == -1) {
      throw new ArgumentError('Model not configured for ${factName}');
    }

    int offset = _factsOffset + factIndex * model._aggregationTypesCount;
    // No items for the corresponding fact, so return null.
    if (aggrFunc != 'count' &&
        aggrFunc != 'avg' &&
        model._aggregations[offset + model._offsetCnt].toInt() == 0) {
      return null;
    }

    if (aggrFuncIndex != -1) {
      return model._aggregations[offset + aggrFuncIndex];
    } else if (aggrFunc == 'count') {
      return model._aggregations[_factsOffset + model._offsetFilteredCount]
          .toInt();
    } else if (aggrFunc == 'avg') {
      return model._aggregations[offset + model._offsetSum] /
          model._aggregations[_factsOffset + model._offsetFilteredCount]
              .toInt();
    } else if (aggrFunc == 'avgOfValid') {
      return model._aggregations[offset + model._offsetSum] /
          model._aggregations[offset + model._offsetCnt].toInt();
    }
    return null;
  }

  dynamic _nonAggregationMember(String key) {
    if (key == 'items') {
      return new _AggregationItemsIterator(model, dimensions, _key);
    }
    return null;
  }

  List<AggregationItem> lowerAggregations() {
    List<AggregationItem> aggregations = new List<AggregationItem>();
    if (dimensions.length == model._dimFields.length) {
      return aggregations;
    }

    var lowerDimensionField = model._dimFields[dimensions.length];
    List lowerVals = model.valuesForDimension(lowerDimensionField);

    lowerVals.forEach((name) {
      List<String> lowerDims = new List.from(dimensions)..add(name);
      AggregationItem entity = model.facts(lowerDims);
      if (entity != null) {
        aggregations.add(entity);
      }
    });

    return aggregations;
  }

  bool containsKey(String key) => fieldNames.contains(key);

  Iterable<String> get fieldNames {
    if (!isValid) {
      throw new StateError('Entity is not valid anymore');
    }

    if (model._itemFieldNamesCache == null) {
      List<String> cache = new List<String>.from(['items', 'children']);
      model._factFields.forEach((var name) {
        AggregationModel.supportedAggregationTypes.forEach((String aggrType) {
          cache.add('${aggrType}(${name})');
        });
      });
      model._itemFieldNamesCache = cache;
    }
    return model._itemFieldNamesCache;
  }

  // TODO(prsd): Implementation of [Observable]
  Stream<List<ChangeRecord>> get changes {
    throw new UnimplementedError();
  }
}

class _AggregationItemsIterator implements Iterator {
  final AggregationModel model;
  List<String> dimensions;
  String key;

  int _current;
  int _counter = 0;

  int _start;
  int _count;
  int _endOfRows;

  _AggregationItemsIterator(
      this.model, List<String> this.dimensions, String this.key) {
    int offset = model._dimToAggrMap[key];
    if (offset != null) {
      int factsEndOffset =
          offset + model._factFields.length * model._aggregationTypesCount;
      _start = model._aggregations[factsEndOffset].toInt();
      _count = model._aggregations[factsEndOffset + 1].toInt();
      _endOfRows = model._rows.length;
    }
  }

  bool moveNext() {
    if (_current == null) {
      _current = _start;
    } else {
      ++_current;
    }

    if (++_counter > _count) {
      return false;
    }

    // If model had a filter applied, then check if _current points to a
    // filtered-in row, else skip till we find one.
    // Also, make sure (even if something else went wrong) we don't go
    // beyond the number of items in the model.
    if (this.model._filterResults != null) {
      while ((this.model._filterResults[_current ~/ AggregationModel.SMI_BITS] &
                  (1 << _current % AggregationModel.SMI_BITS)) ==
              0 &&
          _current <= _endOfRows) {
        ++_current;
      }
    }
    return (_current < _endOfRows);
  }

  get current {
    if (_current == null || _counter > _count) {
      return null;
    }
    return model._rows[model._sorted[_current]];
  }
}
