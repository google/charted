//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// Collection of scales for use by charts. The role of scales is to map the
/// input domain to an output range.
///
/// Charted supports two types of scales:
///   - Quantitative, where the scales use a mathematical function for mapping
///     the input domain to output range.
///   - Ordinal, where the input domain is discrete (i.e set of values)
///
library charted.core.scales;

import 'dart:math' as math;
import 'package:charted/core/utils.dart';
import 'package:charted/format/format.dart';
import 'package:charted/locale/locale.dart';
import 'package:charted/core/interpolators.dart';

part 'scales/ordinal_scale.dart';
part 'scales/linear_scale.dart';
part 'scales/log_scale.dart';


/// Minimum common interface supported by all scales. [QuantitativeScale] and
/// [OrdinalScale] contain the interface for their respective types.
abstract class Scale {
  /// Given a [value] in the input domain, map it to the range.
  /// On [QuantitativeScale]s both parameter and return values are numbers.
  dynamic scale(value);

  /// Given a [value] in the output range, return value in the input domain
  /// that maps to the value.
  /// On [QuantitativeScale]s both parameter and return values are numbers.
  dynamic invert(value);

  /// Input domain used by this scale.
  Iterable domain;

  /// Output range used by this scale.
  Iterable range;

  /// Maximum and minimum values of the scale's output range.
  Extent get rangeExtent;

  /// Creates a clone of this scale.
  Scale clone();

  /// Creates ten tick values over the input domain.
  Iterable ticks([int count = 10]);

  /// Creates a formatter for ticks.
  FormatFunction tickFormatter();
}

/// Minimum common interface supported by all scales whose input domain
/// contains discreet values (Ordinal scales).
abstract class OrdinalScale extends Scale {
  factory OrdinalScale() = _OrdinalScale;

  /// Amount of space that each value in the domain gets from the range. A band
  /// is available only after [rangeBands] or [rangeRoundBands] is called by
  /// the user. A bar-chart could use this space as width of a bar.
  num get rangeBand;

  /// Maps each value on the domain to a single point on output range.  When a
  /// non-zero value is specified, [padding] space is left unused on both ends
  /// of the range.
  void rangePoints(Iterable range, [double padding]);

  /// Maps each value on the domain to a band in the output range.  When a
  /// non-zero value is specified, [padding] space is left between each bands
  /// and [outerPadding] space is left unused at both ends of the range.
  void rangeBands(Iterable range, [double padding, double outerPadding]);

  /// Similar to [rangeBands] but ensures that each band starts and ends on a
  /// pixel boundary - helps avoid anti-aliasing artifacts.
  void rangeRoundBands(Iterable range, [double padding, double outerPadding]);
}

/// Minimum common interface supported by all scales that use a mathematical
/// function to map input domain to output range (Quantitative scales)
/// Examples:
///   - Linear scale which uses a multiplier
///   - Logarithmic scale
abstract class QuantitativeScale extends Scale {
  /// Utility to return extent of sorted [values].
  static Extent extent(Iterable values) =>
      values.first < values.last
          ? new Extent(values.first, values.last)
          : new Extent(values.last, values.first);

  /// Utility method to compute nice extent of input domain.
  static Extent niceExtent(List values, {int floor(num), int ceil(num) }) {
    if (values.first > values.last) {
      values[0] = floor != null ? floor(values.last) : values.last.floor();
      values[values.length - 1] =
          ceil != null ? ceil(values.first) : values.first.floor();
    } else {
      values[0] = floor != null ? floor(values.first) : values.first.floor();
      values[values.length - 1] =
          ceil != null ? ceil(values.last) : values.last.floor();
    }
    return new Extent(values.first, values.last);
  }

  /// Indicates if the current scale is using niced values for ticks
  bool nice;

  /// Indicates if output range is clamped.  When clamp is not true, any input
  /// value that is not within the input domain may result in a value that is
  /// outside the output range.
  bool clamp;

  /// Indicates that the scaled values must be rounded to the nearest
  /// integer.  Helps avoid anti-aliasing artifacts in the visualizations.
  bool rounded;
}


typedef num FloorFunction(num value);
typedef num CeilFunction(num value);

class ScaleUtil {
  static List nice(List values, Pair<FloorFunction, CeilFunction> functions) {
    if (values.last >= values.first) {
      values[0] = functions.first(values.first);
      values[values.length - 1] = functions.last(values.last);
    } else {
      values[values.length - 1] = functions.first(values.last);
      values[0] = functions.last(values.first);
    }
    return values;
  }

  static Pair<FloorFunction, CeilFunction> niceStep(num step) => (step > 0)
      ? new Pair(
          (x) => (x / step).ceil() * step, (x) => (x / step).floor() * step)
      : new Pair(identityFunction, identityFunction);


  /// Returns a Function that given a value x on the domain, returns the
  /// corrsponding value on the range on a bilinear scale.
  ///
  /// @param domain         The domain of the scale.
  /// @param range          The range of the scale.
  /// @param uninterpolator The uninterpolator for domain values.
  /// @param interpolator   The interpolator for range values.
  static Function bilinearScale(List domain, List range,
      Function uninterpolator, Function interpolator) {
    var u = uninterpolator(domain[0], domain[1]),
        i = interpolator(range[0], range[1]);
    return (x) => i(u(x));
  }

  /// Returns a Function that given a value x on the domain, returns the
  /// corrsponding value on the range on a polylinear scale.
  ///
  /// @param domain         The domain of the scale.
  /// @param range          The range of the scale.
  /// @param uninterpolator The uninterpolator for domain values.
  /// @param interpolator   The interpolator for range values.
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

  /// Returns the insertion point i for value x such that all values in a[lo:i]
  /// will be less than x and all values in a[i:hi] will be equal to or greater
  /// than x.
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

  /// Returns the insertion point i for value x such that all values in a[lo:i]
  /// will be less than or equalto x and all values in a[i:hi] will be greater
  /// than x.
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
