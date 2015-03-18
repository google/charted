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
class LogScale extends QuantitativeScale {
  static const defaultBase = 10;
  static const defaultDomain = const [1, 10];

  final LinearScale _linear;
  
  int _base = defaultBase;
  bool _positive = true;
  List _domain = defaultDomain;

  LogScale() : _linear = new LinearScale();
  
  LogScale._clone(LogScale source)
      : _linear = source._linear.clone(),
        _domain = source._domain.toList(),
        _positive = source._positive,
        _base = source._base;

  num _log(x) => (_positive ?
      math.log(x < 0 ? 0 : x) : -math.log(x > 0 ? 0 : -x)) / math.log(base);

  num _pow(x) => _positive ? math.pow(base, x) : -math.pow(base, -x);

  set base(int value) {
    _base = value;
    _linear.domain = _domain.map((e) => _log(e)).toList();
  }
  
  get base => _base;
  
  @override
  num scale(x) => _linear.scale(_log(x));

  @override
  num invert(x) => _pow(_linear.invert(x));

  @override
  set domain(Iterable x) {
    _positive = x.first >= 0;
    _domain = x;
    _linear.domain = _domain.map((e) => _log(e)).toList();
  }
  
  @override
  Iterable get domain => _domain;

  @override
  set range(Iterable newRange) {
    _linear.range = newRange;
  }
  
  @override
  Iterable get range => _linear.range;

  @override
  set rounded(bool value) {
    _linear.rounded = value;
  }
  
  @override
  bool get rounded => _linear.rounded;

  nice_([int ticks]) {
    var niced;
    if (_positive) {
      niced = scaleNice(_domain.map((e) => _log(e)).toList());
    } else {
      var floor = (x) => -(-x).ceil();
      var ceil = (x) => -(-x).floor();
      niced = scaleNice(_domain.map((e) => _log(e)).toList(), floor, ceil);
    }
    _linear.domain = niced;
    domain = niced.map((e) => _pow(e)).toList();
  }

  List ticks([int ticks = 10]) {
    var extent = scaleExtent(_domain),
        ticks = [],
        u = extent[0],
        v = extent[1],
        i = (_log(u)).floor(),
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

  FormatFunction tickFormat(int ticks, [String formatString = null]) {
    var logFormatFunction = formatString != null ?
        format(formatString) : format(".0e");
    var k = math.max(.1, ticks / this.ticks().length),
        e = _positive ? 1e-12 : -1e-12;
    return (d) {
      if (_positive) {
        return d / _pow((_log(d) + e).ceil()) <= k ? logFormatFunction(d) : '';
      } else {
        return d / _pow((_log(d) + e).floor()) <= k ? logFormatFunction(d) : '';
      }
    };
  }

  @override
  LogScale clone() => new LogScale._clone(this);
}
