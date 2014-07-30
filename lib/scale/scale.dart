/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
/*
 * TODO(midoringo): Document library
 */
library charted.scale;

import 'dart:math' as math;
import 'package:charted/core/core.dart';
import 'package:charted/format/format.dart';
import 'package:charted/locale/locale.dart';
import 'package:charted/interpolators/interpolators.dart' as interpolators;

part 'ordinal_scale.dart';
part 'linear_scale.dart';
part 'log_scale.dart';

/** Minimum common interface to be supported by all scales */
abstract class Scale {
  var rangeBand = 0;
  List _domain;
  List _range;
  interpolators.Interpolator _interpolator;
  bool _clamp;


  /**
   * Returns the extent of the scale as a list containing the min and max of the
   * domain.
   */
  List scaleExtent(List domain) {
    var start = domain[0];
    var stop = domain[domain.length - 1];
    return start < stop ? [start, stop] : [stop, start];
  }

  /**
   * Returns the extent of the domain in nice round values.  If alternative
   * floor and ceil functions are not provided, default floor and ceil will be
   * used to produce the round values.
   */
  scaleNice(List domain, [altFloor = null, altCeil = null]) {
    var i0 = 0;
    var i1 = domain.length -1;
    var x0 = domain[i0];
    var x1 = domain[i1];
    var dx;
    if (x1 < x0) {
      dx = i0;
      i0 = i1;
      i1 = dx;
      dx = x0;
      x0 = x1;
      x1 = dx;
    }

    domain[i0] = (altFloor != null) ? altFloor(x0) : x0.floor();
    domain[i1] = (altCeil != null) ? altCeil(x1) : x1.ceil();
    return domain;
  }

  void nice([int ticks = 10]);

  /**
   * Returns the values in the domain as tick values for sub class that doesn't
   * implement the ticks method.
   **/
  List ticks([int ticks = 10]) => _domain;

  /**
   * Returns the identity function as the tickformat Function for sub class that
   * doesn't implment the tickFormat method.
   */
  Function tickFormat(int ticks, [String format = null]) => identityFunction;

  /**
   * Returns a two-element array representing the extent of the scale's range,
   * i.e., the smallest and largest values.
   */
  List rangeExtent() => scaleExtent(_range);

  set domain(List domain);
  get domain => _domain;

  set range(List range);
  get range => _range;

  apply(x);
  Scale copy();
}
