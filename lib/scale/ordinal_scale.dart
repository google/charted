/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.scale;

class OrdinalScale extends Scale {
  Map index = new Map();
  Function _rangeSetupFunction;
  List _rangeSetupArgs = [[]];

  /**
   * Constructs a new ordinal scale with an empty domain and an empty range.
   * The ordinal scale is invalid (always returning undefined) until an output
   * range is specified.
   */
  OrdinalScale() {
    _rangeSetupFunction = defaultRange;
    domain = [];
  }

  /**
   * Given a value x in the input domain, returns the corresponding value in
   * the output range.
   */
  apply(input) {
    if (index[input] == null) {
      index[input] = _domain.length;
      _domain.add(input);
    }
    return range[(index[input]) % range.length];
  }

  List steps(start, step) {
    var s = new Range(domain.length).toList();
    return s.map((num i) => start + step * i).toList();
  }

  void nice([int ticks]) {
    // NO-OP for an ordinal scale.
  }

  /**
   * Sets the domain Value. Setting the domain on an ordinal scale is optional.
   * If no domain is set, a range must be set explicitly. Then, each unique
   * value that is passed to the scale function will be assigned a new value
   * from the output range.
   */
  // TODO(midoringo): It would be nice to be able to match both D3 and dart
  // pattern here.  In D3, if newDomain is not defined, this returns the current
  // domain.  Here we use the Dart syntax for setting and getting domain.
  set domain(List newDomain) {
    _domain = [];
    index = new Map();
    int i = -1;
    int n = newDomain.length;
    var xi;
    while (++i < n) {
      xi = newDomain[i];
      if (index[xi] == null) {
        index[xi] = _domain.length;
        _domain.add(xi);
      }
    }
    Function.apply(_rangeSetupFunction, _rangeSetupArgs);
  }

  get domain => _domain;

  /**
   * Sets the output range of the ordinal scale to the specified array of
   * values. The first element in the domain will be mapped to the first element
   * in values, the second domain value to the second range value, and so on. If
   * there are fewer elements in the range than in the domain, the scale will
   * recycle values from the start of the range.
   */
  set range(List newRange) {
    _range = newRange;
    rangeBand = 0;
    _rangeSetupFunction = defaultRange;
    _rangeSetupArgs = [newRange];
  }

  get range => _range;

  defaultRange(List newRange) {
    range = newRange;
  }

  /**
   * Sets the output range from the specified continuous interval. The array
   * interval contains two elements representing the minimum and maximum numeric
   * value. This interval is subdivided into n evenly-spaced points, where n is
   * the number of (unique) values in the input domain. The first and last point
   * may be offset from the edge of the interval according to the specified
   * padding, which defaults to zero. The padding is expressed as a multiple of
   * the spacing between points. A reasonable value is 1.0, such that the first
   * and last point will be offset from the minimum and maximum value by half
   * the distance between points.
   */
  void rangePoints(List x, [double padding = 0.0]) {
    var start = x[0];
    var stop = x[1];
    var step = (stop - start) / (domain.length - 1 + padding);
    range = steps(domain.length < 2 ?
        (start + stop) / 2 : start + step * padding / 2, step);
    rangeBand = 0;
    _rangeSetupFunction = rangePoints;
    _rangeSetupArgs = [x, padding];
  }

  /**
   * Sets the output range from the specified continuous interval. The array
   * interval contains two elements representing the minimum and maximum numeric
   * value. This interval is subdivided into n evenly-spaced bands, where n is
   * the number of (unique) values in the input domain. The bands may be offset
   * from the edge of the interval and other bands according to the specified
   * padding, which defaults to zero. The padding is typically in the range
   * [0,1] and corresponds to the amount of space in the range interval to
   * allocate to padding. A value of 0.5 means that the band width will be
   * equal to the padding width. The outerPadding argument is for the entire
   * group of bands; a value of 0 means there will be padding only between
   * rangeBands.
   */
  void rangeBands(List x, [double padding = 0.0, double outerPadding]) {
    if (outerPadding == null) outerPadding = padding;

    var reverse = x[1] < x[0] ? 1 : 0,
        start = x[reverse - 0],
        stop = x[1 - reverse],
        step = (stop - start) / (domain.length - padding + 2 * outerPadding);

    range = steps(start + step * outerPadding, step);
    if (reverse > 0) range = _range.reversed.toList();
    rangeBand = step * (1 - padding);
    _rangeSetupFunction = rangeBands;
    _rangeSetupArgs = [x, padding];
  }

  /**
   * Like rangeBands, except guarantees that the band width and offset are
   * integer values, so as to avoid antialiasing artifact
   */
  void rangeRoundBands(List x, [double padding = 0.0, double outerPadding]) {
    if (outerPadding == null) outerPadding = padding;

    var reverse = x[1] < x[0] ? 1 : 0,
        start = x[reverse - 0],
        stop = x[1 - reverse],
        step = ((stop - start) /
            (domain.length - padding + 2 * outerPadding)).floor(),
        error = stop - start - (domain.length - padding) * step;

    range = steps(start + (error / 2).round(), step);
    if (reverse > 0) range = _range.reversed.toList();
    rangeBand = (step * (1 - padding)).round();
    _rangeSetupFunction = rangeRoundBands;
    _rangeSetupArgs = [x, padding];
  }

  List rangeExtent() {
    return scaleExtent(_rangeSetupArgs[0]);
  }

  Scale copy() {
    return new OrdinalScale()
        ..domain = _domain
        ..range = _range
        ..rangeBand = rangeBand
        .._rangeSetupFunction = _rangeSetupFunction
        .._rangeSetupArgs = _rangeSetupArgs;
  }

  /**
   * Returns the value in input domain x for the corresponding value in the
   * output range y.  In Ordinal scale, the output are String values and are not
   * interpolated, so y must match an element in the output range.  Null is
   * returned if the specified y is not an element in range or if the index of
   * the element in range is out of bound of domain's length.
   */
  invert(y) {
    var valueIndex = _range.indexOf(y);
    if (valueIndex > -1 && valueIndex < _domain.length) {
      return _domain[_range.indexOf(y)];
    } else {
      return null;
    }
  }
}
