//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.core.scales;

class _OrdinalScale implements OrdinalScale {
  final _index = new Map<dynamic, int>();

  List _domain = [];
  List _range = [];
  num _rangeBand = 0;
  Extent _rangeExtent;
  Function _reset;

  _OrdinalScale();

  _OrdinalScale._clone(_OrdinalScale source)
      : _domain = new List.from(source._domain),
        _range = new List.from(source._range),
        _reset = source._reset,
        _rangeExtent = source._rangeExtent,
        _rangeBand = source._rangeBand {
    _index.addAll(source._index);
  }

  @override
  scale(dynamic value) {
    if (!_index.containsKey(value)) {
      _index[value] = domain.length;
      _domain.add(value);
    }
    return _range.isNotEmpty
        ? _range.elementAt(_index[value] % _range.length)
        : 0;
  }

  @override
  dynamic invert(value) {
    int position = _range.indexOf(value);
    return position > -1 && position < _domain.length
        ? _domain[position]
        : null;
  }

  @override
  set domain(Iterable values) {
    _domain = [];
    _index.clear();

    for (var i = 0; i < values.length; i++) {
      var value = values.elementAt(i);
      if (_index[value] == null) {
        _index[value] = _domain.length;
        _domain.add(value);
      }
    }

    if (_reset != null) _reset(this);
  }

  @override
  Iterable get domain => _domain;

  @override
  set range(Iterable values) => _setRange(this, values);

  @override
  Iterable get range => _range;

  @override
  Extent get rangeExtent => _rangeExtent;

  @override
  void rangePoints(Iterable range, [double padding = 0.0]) =>
      _setRangePoints(this, range, padding);

  @override
  void rangeBands(Iterable range,
          [double padding = 0.0, double outerPadding]) =>
      _setRangeBands(
          this, range, padding, outerPadding == null ? padding : outerPadding);

  @override
  void rangeRoundBands(Iterable range,
          [double padding = 0.0, double outerPadding]) =>
      _setRangeRoundBands(
          this, range, padding, outerPadding == null ? padding : outerPadding);

  @override
  num get rangeBand => _rangeBand;

  @override
  FormatFunction createTickFormatter([String format]) =>
      (String s) => identityFunction/*<String>*/(s);

  @override
  Iterable get ticks => _domain;

  @override
  OrdinalScale clone() => new _OrdinalScale._clone(this);

  List _steps(start, step) =>
      new Range(domain.length).map((num i) => start + step * i).toList();

  static void _setRange(_OrdinalScale scale, Iterable values) {
    scale._reset = (_OrdinalScale s) {
      s._range = values;
      s._rangeBand = 0;
      s._rangeExtent = null;
    };
    scale._reset(scale);
  }

  static void _setRangePoints(
      _OrdinalScale scale, Iterable range, double padding) {
    scale._reset = (_OrdinalScale s) {
      var start = range.first,
          stop = range.last,
          step = (stop - start - 2 * padding) / (s.domain.length);

      s._range = s._steps(
          s.domain.length < 2 ? (start + stop) / 2 : start + padding, step);
      s._rangeBand = 0;
      s._rangeExtent = new Extent(start, stop);
    };
    if (scale.domain.isNotEmpty) {
      scale._reset(scale);
    }
  }

  static void _setRangeBands(_OrdinalScale scale, Iterable range,
      double padding, double outerPadding) {
    scale._reset = (_OrdinalScale s) {
      var start = range.first,
          stop = range.last,
          step = (stop - start - 2 * outerPadding) /
              (s.domain.length > 1
                  ? (s.domain.length - padding)
                  : 1);

      s._range = s._steps(start + step * outerPadding, step);
      s._rangeBand = step * (1 - padding);
      s._rangeExtent = new Extent(start, stop);
    };
    if (scale.domain.isNotEmpty) {
      scale._reset(scale);
    }
  }

  static void _setRangeRoundBands(_OrdinalScale scale, Iterable range,
      double padding, double outerPadding) {
    scale._reset = (_OrdinalScale s) {
      var start = range.first,
          stop = range.last,
          step =
          ((stop - start - 2 * outerPadding) /
              (s.domain.length > 1
                  ? (s.domain.length - padding)
                  : 1)).floor();

      s._range = s._steps(start + outerPadding, step);
      s._rangeBand = (step * (1 - padding)).round();
      s._rangeExtent = new Extent(start, stop);
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
