/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.scale;

// TODO(midoringo): Write more test for this class.
/**
 * Log scales are similar to linear scales, except there's a logarithmic
 * transform that is applied to the input domain value before the output range
 * value is computed. The mapping to the output range value y can be expressed
 * as a function of the input domain value x: y = m log(x) + b.
 *
 * As log(0) is negative infinity, a log scale must have either an
 * exclusively-positive or exclusively-negative domain; the domain must not
 * include or cross zero. A log scale with a positive domain has a well-defined
 * behavior for positive values, and a log scale with a negative domain has a
 * well-defined behavior for negative values (the input value is multiplied by
 * -1, and the resulting output value is also multiplied by -1). The behavior of
 * the scale is undefined if you pass a negative value to a log scale with a
 * positive domain or vice versa.
 */
class LogScale extends Scale {
  Function input;
  Function output;
  static const defaultBase = 10;
  static const defaultDomain = const [1, 10];

  LinearScale _linear;
  int _base;
  bool _positive;
  List _domain;

  LogScale([LinearScale linear = null,
      this._base = defaultBase,
      this._positive = true,
      this._domain = defaultDomain]) {
    _linear = (linear != null) ? linear : new LinearScale(_domain);
  }

  num _log(x) => (_positive ? math.log(x < 0 ? 0 : x) :
      -math.log(x > 0 ? 0 : -x)) / math.log(_base);

  _pow(x) => _positive ? math.pow(_base, x) : -math.pow(_base, -x);

  /**
   * Given a value x in the input domain, returns the corresponding value in
   * the output range.
   */
  apply(x) => _linear.apply(_log(x));

  /**
   * Returns the value in the input domain x for the corresponding value in the
   * output range y. This represents the inverse mapping from range to domain.
   * For a valid value y in the output range, log(log.invert(y)) equals y;
   * similarly, for a valid value x in the input domain, log.invert(log(x))
   * equals x. Equivalently, you can construct the invert operator by building
   * a new scale while swapping the domain and range. The invert operator is
   * particularly useful for interaction, say to determine the value in the
   * input domain that corresponds to the pixel location under the mouse.
   */
  invert(x) => _pow(_linear.invert(x));

  /** Sets the domain of the scale. */
  set domain(List x) {
    _positive = x[0] >= 0;
    _domain = x;
    _linear.domain = _domain.map((e) => _log(e)).toList();
  }
  get domain => _domain;

  /** Sets the base of the logarithmic scale. */
  get base => _base;
  set base(int newBase) {
    this._base = newBase;
    _linear.domain = _domain.map((e) => _log(e)).toList();
  }

  /** Sets the range of the scale. */
  get range => _linear.range;
  set range(List newRange) {
    _linear.range = newRange;
  }

  /**
   * Sets the scale's output range to the specified array of values, while also
   * setting the scale's interpolator to d3.interpolateRound. This is a
   * convenience routine for when the values output by the scale should be
   * exact integers, such as to avoid antialiasing artifacts. It is also
   * possible to round the output values manually after the scale is applied.
   */
  void rangeRound(List newRange) {
    _linear.rangeRound(newRange);
  }

  /** Sets the interpolator used in the scale. */
  set interpolator(interpolators.Interpolator newInterpolator) {
    _linear.interpolator = newInterpolator;
  }

  get interpolator => _linear.interpolator;

  /**
   * Enables or disables clamping accordingly. By default, clamping is
   * disabled, such that if a value outside the input domain is passed to the
   * scale, the scale may return a value outside the output range through linear
   * extrapolation.
   */
  set clamp(bool clamp) {
    _linear.clamp = clamp;
  }

  get clamp => _linear.clamp;

  /**
   * Extends the domain so that it starts and ends on nice round values.
   * The optional tick count argument allows greater control over the step size
   * used to extend the bounds, guaranteeing that the returned ticks will
   * exactly cover the domain.
   **/
  nice([int ticks]) {
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

  /**
   * Returns representative values from the scale's input domain. The returned
   * tick values are uniformly spaced within each power of ten,
   * and are guaranteed to be within the extent of the input domain.
   */
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

  /**
   * Returns a number format function suitable for displaying a tick value.
   * The returned tick format is implemented as d.toPrecision(1)
   */
  Function tickFormat(int ticks, [String formatString = null]) {
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

  copy() {
    return new LogScale(_linear.copy(), _base, _positive, _domain);
  }
}
