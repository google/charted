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
import 'package:charted/core/interpolators.dart';
import 'package:charted/core/time_interval.dart';
import 'package:charted/locale/locale.dart';
import 'package:charted/locale/format.dart';

part 'scales/ordinal_scale.dart';
part 'scales/linear_scale.dart';
part 'scales/log_scale.dart';
part 'scales/time_scale.dart';

typedef num RoundFunction(num value);

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

  /// Creates tick values over the input domain.
  Iterable get ticks;

  /// Creates a formatter that is suitable for formatting the ticks.
  /// For ordinal scale, the returned function is an identity function.
  FormatFunction createTickFormatter([String format]);

  /// Creates a clone of this scale.
  Scale clone();

  /// Suggested number of ticks on this scale.
  /// Note: This property is only valid on quantitative scales.
  int ticksCount;

  /// Forces the number of ticks on this scale to be the forcedTicksCount.
  /// The tick values on the scale does not guarantee to be niced numbers, but
  /// domain of the scale does.
  /// Note: This property is only valid on quantitative scales.
  int forcedTicksCount;

  /// Indicates if the current scale is using niced values for ticks.
  /// Note: This property is only valid on quantitative scales.
  bool nice;

  /// Indicates if output range is clamped.  When clamp is not true, any input
  /// value that is not within the input domain may result in a value that is
  /// outside the output range.
  /// Note: This property is only valid on quantitative scales.
  bool clamp;

  /// Indicates that the scaled values must be rounded to the nearest
  /// integer.  Helps avoid anti-aliasing artifacts in the visualizations.
  /// Note: This property is only valid on quantitative scales.
  bool rounded;
}

/// Minimum common interface supported by scales whose input domain
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

class RoundingFunctions extends Pair<RoundFunction, RoundFunction> {
  RoundingFunctions(RoundFunction floor, RoundFunction ceil)
      : super(floor, ceil);

  factory RoundingFunctions.defaults() =>
      new RoundingFunctions((x) => x.floor(), (x) => x.ceil());

  factory RoundingFunctions.identity() => new RoundingFunctions(
      (num n) => identityFunction/*<num>*/(n),
      (num n) => identityFunction/*<num>*/(n));

  RoundFunction get floor => super.first;
  RoundFunction get ceil => super.last;
}

/// Namespacing container for utilities used by scales.
abstract class ScaleUtils {
  /// Utility to return extent of sorted [values].
  static Extent extent(Iterable values) => values.first < values.last
      ? new Extent(values.first, values.last)
      : new Extent(values.last, values.first);

  /// Extends [values] to round numbers based on the given pair of
  /// floor and ceil functions.  [functions] is a pair of rounding function
  /// among which the first is used to compute floor of a number and the
  /// second for ceil of the number.
  static List nice(List values, RoundingFunctions functions) {
    if (values.last >= values.first) {
      values[0] = functions.floor(values.first);
      values[values.length - 1] = functions.ceil(values.last);
    } else {
      values[values.length - 1] = functions.floor(values.last);
      values[0] = functions.ceil(values.first);
    }
    return values;
  }

  static RoundingFunctions niceStep(num step) => (step > 0)
      ? new RoundingFunctions(
          (x) => (x < step) ? x.floor() : (x / step).floor() * step,
          (x) => (x < step) ? x.ceil() : (x / step).ceil() * step)
      : new RoundingFunctions.identity();

  /// Returns a Function that given a value x on the domain, returns the
  /// corresponding value on the range on a bilinear scale.
  ///
  /// @param domain         The domain of the scale.
  /// @param range          The range of the scale.
  /// @param uninterpolator The uninterpolator for domain values.
  /// @param interpolator   The interpolator for range values.
  static Function bilinearScale(
      List domain, List range, Function uninterpolator, Function interpolator) {
    var u = uninterpolator(domain[0], domain[1]),
        i = interpolator(range[0], range[1]);
    return (x) => i(u(x));
  }

  /// Returns a Function that given a value x on the domain, returns the
  /// corresponding value on the range on a polylinear scale.
  ///
  /// @param domain         The domain of the scale.
  /// @param range          The range of the scale.
  /// @param uninterpolator The uninterpolator for domain values.
  /// @param interpolator   The interpolator for range values.
  static Function polylinearScale(
      List domain, List range, Function uninterpolator, Function interpolator) {
    var u = [], i = [], j = 0, k = math.min(domain.length, range.length) - 1;

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
