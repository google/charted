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
import "dart:collection";

part 'color.dart';
part 'lists.dart';
part 'math.dart';
part 'namespace.dart';
part 'object_factory.dart';
part 'rect.dart';

const String ORIENTATION_LEFT = 'left';
const String ORIENTATION_RIGHT = 'right';
const String ORIENTATION_TOP = 'top';
const String ORIENTATION_BOTTOM = 'bottom';

const String EASE_TYPE_LINEAR = 'linear';
const String EASE_TYPE_POLY = 'poly';
const String EASE_TYPE_QUAD = 'quad';
const String EASE_TYPE_CUBIC = 'cubic';
const String EASE_TYPE_SIN = 'sin';
const String EASE_TYPE_EXP = 'exp';
const String EASE_TYPE_CIRCLE = 'circle';
const String EASE_TYPE_ELASTIC = 'elastic';
const String EASE_TYPE_BACK = 'back';
const String EASE_TYPE_BOUNCE = 'bounce';

const String EASE_MODE_IN = 'in';
const String EASE_MODE_OUT = 'out';
const String EASE_MODE_IN_OUT = 'in-out';
const String EASE_MODE_OUT_IN = 'out-in';

/** IdentityFunction */
identityFunction(x) => x;

/** Utility method to test if [val] is null or isEmpty */
bool isNullOrEmpty(val) => val == null || val.isEmpty;

/** Class representing a pair of values */
class Pair<T1, T2> {
  final T1 first;
  final T2 last;

  const Pair(this.first, this.last);

  bool operator==(Pair other) =>
      other != null && first == other.first && last == other.last;
}

/*
 * TODO(prsd): Move everything below this comment to the respective
 * sub-libraries.
 */

class ScaleUtil {
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

