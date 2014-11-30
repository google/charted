/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

/** Returns a sum of all values in the given list of values */
num sum(List values) =>
    values == null || values.isEmpty ?
        0: values.fold(0.0, (old, next) => old + next);

/** Returns the smallest number in the given list of values */
num min(Iterable values) =>
    values == null || values.isEmpty ?
        null : values.fold(values.elementAt(0), math.min);

/** Returns the largest number in the given list of values */
num max(Iterable values) =>
    values == null || values.isEmpty ?
        null : values.fold(values.elementAt(0), math.max);

/**
 * Represents a tuple of mininum and maximum values in a List.
 */
class Extent<T> extends Pair<T, T> {
  final T min;
  final T max;

  factory Extent.items(Iterable<T> items,
      [ Comparator compare = Comparable.compare ]) {
    if (items.length == 0) return new Extent(null, null);
    var max = items.first,
        min = items.first;
    for (var value in items) {
      if (compare(max, value) < 0) max = value;
      if (compare(min, value) > 0) min = value;
    }
    return new Extent(min, max);
  }

  const Extent(T min, T max) : min = min, max = max, super(min, max);
}

/**
 * Iterable representing a range of values containing the start, stop
 * and each of the step values between them.
 */
class Range extends IterableBase<num> {
  final List<num> _range = <num>[];

  factory Range.integers(num start, [num stop, num step = 1]) =>
      new Range(start, stop, step, true);

  Range(num start, [num stop, num step = 1, bool integers = false]) {
    if (stop == null) {
      stop = start;
      start = 0;
    }

    if (step == 0 || start < stop && step < 0 || start > stop && step > 0) {
      throw new ArgumentError('Invalid range.');
    }

    var k = _integerConversionFactor(step.abs()),
        i = -1,
        j;

    start *= k;
    stop *= k;
    step *= k;

    if (step < 0) {
      while ((j = start + step * ++i) > stop) {
        _range.add(integers ? j ~/ k : j / k);
      }
    } else {
      while ((j = start + step * ++i) < stop) {
        _range.add(integers ? j ~/ k : j / k);
      }
    }
  }

  @override
  int get length => _range.length;

  @override
  num elementAt(int index) => _range.elementAt(index);

  @override
  Iterator get iterator => _range.iterator;

  static int _integerConversionFactor(num val) {
    int k = 1;
    while (val * k % 1 > 0) {
      k *= 10;
    }
    return k;
  }
}
