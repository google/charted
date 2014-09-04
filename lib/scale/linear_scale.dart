/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.scale;

class LinearScale extends Scale {
  Function input;
  Function output;
  static const defaultDomainRange = const [0, 1];

  /**
   * Constructs a new linear scale with the default domain [0,1] and the default
   * range [0,1]. Thus, the default linear scale is equivalent to the identity
   * function for numbers; for example linear(0.5) returns 0.5.
   */
  LinearScale([List domain = defaultDomainRange,
      List range = defaultDomainRange,
      interpolators.Interpolator interpolator = interpolators.interpolateNumber,
      bool clamp = false]) {
    _initializeScale(domain, range, interpolator, clamp);
  }

  _initializeScale(List domain, List range,
      interpolators.Interpolator interpolator, bool clamp) {
    _domain = domain;
    _range = range;
    _interpolator = interpolator;
    _clamp = clamp;

    Function linear = math.min(domain.length, range.length) > 2 ?
        ScaleUtil.polylinearScale: ScaleUtil.bilinearScale;
    Function uninterpolator = clamp ? interpolators.uninterpolateClamp :
        interpolators.uninterpolateNumber;
    if (range[0] is num) {
      input = linear(range, domain, uninterpolator,
          interpolators.interpolateNumber);
    }
    output = linear(domain, range, uninterpolator, interpolator);
  }

  /**
   * Given a value x in the input domain, returns the corresponding value in
   * the output range.
   */
  apply(x) {
    _initializeScale(_domain, _range, _interpolator, _clamp);
    return output(x);
  }

  /**
   * Returns the value in the input domain x for the corresponding value in the
   * output range y. This represents the inverse mapping from range to domain.
   * If elements in range are not number, the invert function returns null.
   */
  invert(y) {
    _initializeScale(_domain, _range, _interpolator, _clamp);
    return input != null ? input(y) : null;
  }

  /** Sets the domain of the scale. */
  set domain(List newDomain) {
    _domain = newDomain;
  }

  get domain => _domain;

  /** Sets the range of the scale. */
  set range(List newRange) {
    _range = newRange;
  }

  get range => _range;

  /**
   * Sets the scale's output range to the specified array of values, while also
   * setting the scale's interpolator to d3.interpolateRound. This is a
   * convenience routine for when the values output by the scale should be
   * exact integers, such as to avoid antialiasing artifacts. It is also
   * possible to round the output values manually after the scale is applied.
   */
  rangeRound(List newRange) {
    _initializeScale(_domain, newRange, interpolators.interpolateRound, _clamp);
  }

  /**
   * Enables or disables clamping accordingly. By default, clamping is
   * disabled, such that if a value outside the input domain is passed to the
   * scale, the scale may return a value outside the output range through linear
   * extrapolation.
   */
  set clamp(bool clamp) {
    _clamp = clamp;
  }

  get clamp => _clamp;

  /**
   * Sets the interpolator of the scale.  If it's not set, the scale will try to
   * find the correct interpolator base on the domain and range input.
   */
  set interpolator(interpolators.Interpolator newInterpolator) {
    _interpolator = newInterpolator;
  }

  get interpolator => _interpolator;

  /** Sets the amount of ticks in the scale, default is 10. */
  List ticks([int ticks = 10]) {
    return _linearTicks(domain, ticks);
  }

  Function tickFormat(int ticks, [String format = null]) {
    return _linearTickFormat(_domain, ticks, format);
  }

  _linearTickFormat(List domain, int ticks, String format) {
    var tickRange = _linearTickRange(domain, ticks);
    return new EnusLocale().numberFormat.format((format != null) ?
        format : ",." + _linearPrecision(tickRange[2]).toString() + "f");
  }

  // Returns the number of significant digits after the decimal point.
  int _linearPrecision(value) {
    return -(math.log(value) / math.LN10 + .01).floor();
  }

  /**
   * Extends the domain so that it starts and ends on nice round values.
   * The optional tick count argument allows greater control over the step size
   * used to extend the bounds, guaranteeing that the returned ticks will
   * exactly cover the domain.
   **/
  void nice([int ticks = 10]) {
    _domain = _linearNice(_domain, ticks);
  }

  /**
   * Returns an exact copy of this linear scale. Changes to this scale will not
   * affect the returned scale, and vice versa.
   **/
  LinearScale copy() => new LinearScale(_domain, _range, _interpolator, _clamp);

  List _linearNice(List domain, [int ticks = 10]) {
    return ScaleUtil.nice(domain,
        ScaleUtil.niceStep(_linearTickRange(domain, ticks)[2]));
  }

  List _linearTicks(List domain, int ticks) {
    List args = _linearTickRange(domain, ticks);
    return new Range(args[0], args[1], args[2]).toList();
  }

  List _linearTickRange(List domain, int ticks) {
    var extent = scaleExtent(domain),
        span = extent[1] - extent[0],
        step = math.pow(10, (math.log(span / ticks) / math.LN10).floor()),
        err = ticks / span * step;

    // Filter ticks to get closer to the desired count.
    if (err <= .15) step *= 10;
    else if (err <= .35) step *= 5;
    else if (err <= .75) step *= 2;

    List tickRange = new List(3);
    // Round start and stop values to step interval.
    tickRange[0] = (extent[0] / step).ceil() * step;
    tickRange[1] = (extent[1] / step).floor() * step + step * .5; // inclusive
    tickRange[2] = step;
    return tickRange;
  }

  get linearTickRange => _linearTickRange;
}
