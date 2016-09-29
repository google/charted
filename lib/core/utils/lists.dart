//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.utils;

/// Returns a sum of all values in the given list of values
num sum(List values) => values == null || values.isEmpty
    ? 0
    : values.fold(0.0, (old, next) => old + next);

/// Returns the smallest number in the given list of values
num min(Iterable values) => values == null || values.isEmpty
    ? null
    : values.fold(values.elementAt(0) as num, math.min);

/// Returns the largest number in the given list of values
num max(Iterable values) => values == null || values.isEmpty
    ? null
    : values.fold(values.elementAt(0) as num, math.max);

/// Represents a constant pair of values
class Pair<T1, T2> {
  final T1 first;
  final T2 last;

  const Pair(this.first, this.last);

  bool operator ==(other) =>
      other is Pair && first == other.first && last == other.last;

  int get hashCode => hash2(first, last);
}

/// Represents a pair of mininum and maximum values in a List.
class Extent<T> extends Pair<T, T> {
  final T min;
  final T max;

  factory Extent.items(Iterable<T> items,
      [Comparator compare = Comparable.compare]) {
    if (items.length == 0) return new Extent(null, null);
    var max = items.first, min = items.first;
    for (var value in items) {
      if (compare(max, value) < 0) max = value;
      if (compare(min, value) > 0) min = value;
    }
    return new Extent(min, max);
  }

  const Extent(T min, T max)
      : min = min,
        max = max,
        super(min, max);
}

/// Iterable representing a range of values containing the start, stop
/// and each of the step values between them.
class Range extends DelegatingList<num> {
  final num start;
  final num stop;
  final num step;

  factory Range.integers(num start, [num stop, num step = 1]) =>
      new Range(start, stop, step, true);

  factory Range(num start, [num stop, num step = 1, bool integers = false]) {
    List<num> values = <num>[];

    if (stop == null) {
      stop = start;
      start = 0;
    }

    if (step == 0 || start < stop && step < 0 || start > stop && step > 0) {
      throw new ArgumentError('Invalid range.');
    }

    var k = _integerConversionFactor(step.abs()), i = -1, j;

    start *= k;
    stop *= k;
    step *= k;

    if (step < 0) {
      while ((j = start + step * ++i) > stop) {
        values.add(integers ? j ~/ k : j / k);
      }
    } else {
      while ((j = start + step * ++i) < stop) {
        values.add(integers ? j ~/ k : j / k);
      }
    }

    return new Range._internal(start, stop, step, values);
  }

  Range._internal(this.start, this.stop, this.step, List<num> values)
      : super(values);

  static int _integerConversionFactor(num val) {
    int k = 1;
    while (val * k % 1 > 0) {
      k *= 10;
    }
    return k;
  }
}
