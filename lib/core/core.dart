/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.core;

import "dart:html" show Element;
import "dart:math" as math;

part 'color.dart';
part 'lists.dart';
part 'math.dart';
part 'namespace.dart';
part 'object_factory.dart';

/**
 * Callback for all DOM related operations - The first parameter
 * [datum] is the piece of data associated with the node, [ei] is
 * the index of the element in it's group and [c] is the Element to
 * which the data is associated to.
 */
typedef E ChartedCallback<E>(datum, int ei, Element c);

/** Callback used to access a value from a datum */
typedef E ChartedValueAccessor<E>(datum, int ei);

/** Create a ChartedCallback that always returns [val] */
ChartedCallback toCallback(val) => (d, i, e) => val;

/** Create a ChartedValueAccessor that always returns [val] */
ChartedValueAccessor toValueAccessor(val) => (d, i) => val;

/** IdentityFunction */
identityFunction(x) => x;

/** Class representing a pair of values */
class ChartedPair<T1, T2> {
  final T1 first;
  final T2 last;
  ChartedPair(this.first, this.last);
}

/*
 * TODO(prsd): Move everything below this comment to the respective
 * sub-libraries.
 */

class ScaleUtil {
  /** Returns the smallest k(k ∈ 10^n) such that x * k is an integer. */
    static int integerScaleRange(num x) {
      int k = 1;
      while (x * k % 1 > 0) {
        k *= 10;
      }
      return k;
    }

  /**
   * Returns the list containing the start, stop, and each of the step values
   * beteween the start and stop value.
   */
  static List range(num start, [num stop = -1, num step = 1]) {
    if (stop == -1) {
      stop = start;
      start = 0;
    }
    if ((stop - start) / step == double.INFINITY) {
      throw new RangeError('infinite range');
    }
    List range = [];
    var k = integerScaleRange(step.abs());
    var i = -1;
    var j;
    start *= k;
    stop *= k;
    step *= k;
    if (step < 0) {
      while ((j = start + step * ++i) > stop) {
        range.add(j / k);
      }
    } else {
      while ((j = start + step * ++i) < stop) {
        range.add(j / k);
      }
    }
    return range;
  }

  static List nice(List domain, Nice nice) {
    var i0 = 0,
        i1 = domain.length - 1,
        x0 = domain[i0],
        x1 = domain[i1],
        dx;

    if (x1 < x0) {
      dx = i0;
      i0 = i1;
      i1 = dx;
      dx = x0;
      x0 = x1;
      x1 = dx;
    }

    domain[i0] = nice.floor(x0);
    domain[i1] = nice.ceil(x1);
    return domain;
  }

  static Nice _niceIdentity = new Nice(identityFunction, identityFunction);

  static Nice niceStep(num step) {
    return (step > 0) ? new Nice((x) => (x / step).ceil() * step,
        (x) => (x / step).floor() * step) : _niceIdentity;
  }

  /**
   * Returns a Function that given a value x on the domain, returns the
   * corrsponding value on the range on a bilinear scale.
   *
   * @param domain         The domain of the scale.
   * @param range          The range of the scale.
   * @param uninterpolator The uninterpolator for domain values.
   * @param interpolator   The interpolator for range values.
   */
  static Function bilinearScale(List domain, List range,
      Function uninterpolator, Function interpolator) {
    var u = uninterpolator(domain[0], domain[1]),
        i = interpolator(range[0], range[1]);
    return (x) => i(u(x));
  }

  /**
   * Returns a Function that given a value x on the domain, returns the
   * corrsponding value on the range on a polylinear scale.
   *
   * @param domain         The domain of the scale.
   * @param range          The range of the scale.
   * @param uninterpolator The uninterpolator for domain values.
   * @param interpolator   The interpolator for range values.
   */
  static Function polylinearScale(List domain, List range,
      Function uninterpolator, Function interpolator) {
    var u = [],
        i = [],
        j = 0,
        k = math.min(domain.length, range.length) - 1;

    // Handle descending domains.
    if (domain[k] < domain[0]) {
      domain = domain.reversed.toList();
      range = range.reversed.toList();
    }

    while (++j <= k) {
      u.add(uninterpolator(domain[j - 1], domain[j]));
      i.add(interpolator(range[j - 1], range[j]));
    }

    return (x) {
      int index = bisect(domain, x, 1, k) - 1;
      return i[index](u[index](x));
    };
  }

  /**
   * Returns the insertion point i for value x such that all values in a[lo:i]
   * will be less than x and all values in a[i:hi] will be equal to or greater
   * than x.
   */
  static int bisectLeft(List a, num x, [int lo = 0, int hi = -1]) {
    if (hi == -1) {
      hi = a.length;
    }
    while (lo < hi) {
      int mid = ((lo + hi) / 2).floor();
      if (a[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /**
   * Returns the insertion point i for value x such that all values in a[lo:i]
   * will be less than or equalto x and all values in a[i:hi] will be greater
   * than x.
   */
  static int bisectRight(List a, num x, [int lo = 0, int hi = -1]) {
    if (hi == -1) {
      hi = a.length;
    }
    while (lo < hi) {
      int mid = ((lo + hi) / 2).floor();
      if (x < a[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  static Function bisect = bisectRight;
}

class Nice {
  Function _floor;
  Function _ceil;
  Nice(Function this._ceil, Function this._floor);
  set floor(Function f) {
    _floor = f;
  }
  get floor => _floor;
  set ceil(Function f) {
      _ceil = f;
    }
  get ceil => _ceil;
}

