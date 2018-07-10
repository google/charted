//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.core.scales;

class _OrdinalScale<TDomain extends Comparable, TRange>
    implements OrdinalScale<TDomain, TRange> {
  final Map<TDomain, int> _index = {};
  final List<TDomain> _domain;
  List<TRange> _range;
  num _rangeBand = 0;
  Extent<TDomain> _rangeExtent;
  void Function(_OrdinalScale<TDomain, TRange>) _reset;

  _OrdinalScale()
      : _domain = [],
        _range = [];

  _OrdinalScale._clone(_OrdinalScale<TDomain, TRange> source)
      : _domain = new List.from(source._domain),
        _range = new List.from(source._range),
        _reset = source._reset,
        _rangeExtent = source._rangeExtent,
        _rangeBand = source._rangeBand {
    _index.addAll(source._index);
  }

  @override
  TRange scale(TDomain value) {
    if (!_index.containsKey(value)) {
      _index[value] = domain.length;
      _domain.add(value);
    }
    return _range.isNotEmpty
        ? _range.elementAt(_index[value] % _range.length)
        : null;
  }

  @override
  TDomain invert(TRange value) {
    int position = _range.indexOf(value);
    return position > -1 && position < _domain.length
        ? _domain[position]
        : null;
  }

  @override
  set domain(Iterable<TDomain> values) {
    _domain.clear();
    _index.clear();

    for (var value in values) {
      if (_index[value] == null) {
        _index[value] = _domain.length;
        _domain.add(value);
      }
    }

    if (_reset != null) _reset(this);
  }

  @override
  Iterable<TDomain> get domain => _domain;

  @override
  set range(Iterable<TRange> values) {
    _reset = (_OrdinalScale<TDomain, TRange> s) {
      s._range = new List<TRange>.from(values);
      s._rangeBand = 0;
      s._rangeExtent = null;
    };
    _reset(this);
  }

  @override
  Iterable<TRange> get range => _range;

  @override
  Extent<TDomain> get rangeExtent => _rangeExtent;

  @override
  void rangePoints(Iterable<num> range, [double padding = 0.0]) =>
      _setRangePoints(this, range, padding);

  @override
  void rangeBands(Iterable<num> range,
          [double padding = 0.0, double outerPadding]) =>
      _setRangeBands(this, range, padding, outerPadding ?? padding);

  @override
  void rangeRoundBands(Iterable<num> range,
          [double padding = 0.0, double outerPadding]) =>
      _setRangeRoundBands(this, range, padding, outerPadding ?? padding);

  @override
  num get rangeBand => _rangeBand;

  @override
  FormatFunction createTickFormatter([String format]) =>
      (dynamic s) => s.toString();

  @override
  Iterable get ticks => _domain;

  @override
  OrdinalScale clone() => new _OrdinalScale._clone(this);

  List _steps(num start, num step) =>
      new Range(domain.length).map((num i) => start + step * i).toList();

  static void _setRangePoints(
      _OrdinalScale scale, Iterable<num> range, double padding) {
    scale._reset = (_OrdinalScale s) {
      var start = range.first;
      var stop = range.last;
      var step = s.domain.length > 1
          ? (stop - start - 2 * padding) / (s.domain.length - 1)
          : 0;

      s._range = s._steps(
          s.domain.length < 2 ? (start + stop) / 2 : start + padding, step);
      s._rangeBand = 0;
      s._rangeExtent = new Extent<num>(start, stop);
    };
    if (scale.domain.isNotEmpty) {
      scale._reset(scale);
    }
  }

  static void _setRangeBands(_OrdinalScale scale, Iterable range,
      double padding, double outerPadding) {
    scale._reset = (_OrdinalScale s) {
      num start = range.first,
          stop = range.last,
          step = (stop - start - 2 * outerPadding) /
              (s.domain.length > 1 ? (s.domain.length - padding) : 1);

      s._range = s._steps(start + step * outerPadding, step);
      s._rangeBand = step * (1 - padding);
      s._rangeExtent = new Extent<num>(start, stop);
    };
    if (scale.domain.isNotEmpty) {
      scale._reset(scale);
    }
  }

  static void _setRangeRoundBands(_OrdinalScale scale, Iterable<num> range,
      double padding, double outerPadding) {
    scale._reset = (_OrdinalScale s) {
      num start = range.first,
          stop = range.last,
          step = ((stop - start - 2 * outerPadding) /
                  (s.domain.length > 1 ? (s.domain.length - padding) : 1))
              .floor();

      s._range = s._steps(start + outerPadding, step);
      s._rangeBand = (step * (1 - padding)).round();
      s._rangeExtent = new Extent<num>(start, stop);
    };
    if (scale.domain.isNotEmpty) {
      scale._reset(scale);
    }
  }

  //
  // Properties that are valid only on quantitative scales.
  //
  bool clamp;
  bool nice;
  bool rounded;
  int ticksCount;
  int forcedTicksCount;
}
