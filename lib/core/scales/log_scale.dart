//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.core.scales;

/// Log scale is similar to linear scale, except there's a logarithmic
/// transform that is applied to the input domain value before the output
/// range value is computed.
///
/// The mapping to the output range value y can be expressed as a function
/// of the input domain value x: y = m log(x) + b.
///
/// As log(0) is negative infinity, a log scale must have either an
/// exclusively-positive or exclusively-negative domain; the domain must not
/// include or cross zero.
class LogScale implements Scale<num, num> {
  static const defaultBase = 10;
  static const defaultDomain = const [1, 10];
  static final negativeNumbersRoundFunctionsPair =
      new RoundingFunctions((x) => -((-x).floor()), (x) => -((-x).ceil()));

  final LinearScale _linear;

  bool _nice = false;
  int _base = defaultBase;
  int _ticksCount = 10;
  bool _positive = true;
  List<num> _domain = defaultDomain;

  LogScale() : _linear = new LinearScale();

  LogScale._clone(LogScale source)
      : _linear = source._linear.clone(),
        _domain = source._domain.toList(),
        _positive = source._positive,
        _base = source._base,
        _nice = source._nice,
        _ticksCount = source._ticksCount;

  num _log(num x) =>
      (_positive ? math.log(x < 0 ? 0 : x) : -math.log(x > 0 ? 0 : -x)) /
      math.log(base);

  num _pow(num x) => _positive ? math.pow(base, x) : -math.pow(base, -x);

  set base(int value) {
    if (_base != value) {
      _base = value;
      _reset();
    }
  }

  int get base => _base;

  @override
  num scale(num x) => _linear.scale(_log(x));

  @override
  num invert(num x) => _pow(_linear.invert(x));

  @override
  set domain(covariant List<num> values) {
    _positive = values.first >= 0;
    _domain = values;
    _reset();
  }

  @override
  Iterable<num> get domain => _domain;

  @override
  set range(Iterable<num> newRange) {
    _linear.range = newRange;
  }

  @override
  Iterable<num> get range => _linear.range;

  @override
  set rounded(bool value) {
    _linear.rounded = value;
  }

  @override
  bool get rounded => _linear.rounded;

  @override
  set nice(bool value) {
    if (_nice != value) {
      _nice = value;
      _reset();
    }
  }

  @override
  bool get nice => _nice;

  @override
  set ticksCount(int value) {
    if (_ticksCount != value) {
      _ticksCount = value;
      _reset();
    }
  }

  @override
  int get ticksCount => _ticksCount;

  @override
  set clamp(bool value) {
    _linear.clamp = value;
  }

  @override
  bool get clamp => _linear.clamp;

  @override
  Extent get rangeExtent => _linear.rangeExtent;

  void _reset() {
    if (_nice) {
      var niced = _domain.map((num e) => _log(e)).toList();
      var roundFunctions = _positive
          ? new RoundingFunctions.defaults()
          : negativeNumbersRoundFunctionsPair;

      _linear.domain = ScaleUtils.nice(niced, roundFunctions);
      _domain = niced.map((e) => _pow(e)).toList();
    } else {
      _linear.domain = _domain.map((num e) => _log(e)).toList();
    }
  }

  @override
  Iterable<num> get ticks {
    var extent = ScaleUtils.extent(_domain);
    var ticks = <num>[];
    num u = extent.min, v = extent.max;
    int i = (_log(u)).floor(),
        j = (_log(v)).ceil(),
        n = (_base % 1 > 0) ? 2 : _base;

    if ((j - i).isFinite) {
      if (_positive) {
        for (; i < j; i++) for (var k = 1; k < n; k++) ticks.add(_pow(i) * k);
        ticks.add(_pow(i));
      } else {
        ticks.add(_pow(i));
        for (; i++ < j;) for (var k = n - 1; k > 0; k--) ticks.add(_pow(i) * k);
      }
      for (i = 0; ticks[i] < u; i++) {} // strip small values
      for (j = ticks.length; ticks[j - 1] > v; j--) {} // strip big values
      ticks = ticks.sublist(i, j);
    }
    return ticks;
  }

  @override
  FormatFunction createTickFormatter([String formatStr]) {
    FormatFunction logFormatFunction =
        Scale.numberFormatter.format(formatStr != null ? formatStr : ".0E");
    var k = math.max(.1, ticksCount / this.ticks.length),
        e = _positive ? 1e-12 : -1e-12;
    return (dynamic _d) {
      var d = _d as num;
      if (_positive) {
        return d / _pow((_log(d) + e).ceil()) <= k ? logFormatFunction(d) : '';
      } else {
        return d / _pow((_log(d) + e).floor()) <= k ? logFormatFunction(d) : '';
      }
    };
  }

  @override
  LogScale clone() => new LogScale._clone(this);

  // TODO(midoringo): Implement this for the log scale.
  @override
  int forcedTicksCount;
}
