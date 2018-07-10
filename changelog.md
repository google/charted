# Changelog
All notable changes to this project will be documented in this file.

This log starts from version 0.5.0. Older versions are omitted, but this should
be kept up-to-date when a version update happens in the future.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## 0.6.0 - 2018-07-09


### Changed
- Internal changes to make charted Dart 2.0 compatible.

- Several typedef signatures have changed: `CompareFunc`,
  `InterpolatorGenerator`:

  |         | Breaking typedef signature changes |
  |---------|------------------------------------|
  | **OLD** | `typedef int CompareFunc(dynamic a, dynamic b);`
  | **NEW** | `typedef int CompareFunc(Comparable a, Comparable b);`
  |         |                                    |
  | **OLD** | `typedef Interpolator InterpolatorGenerator(a, b);`
  | **NEW** | `typedef Interpolator InterpolatorGenerator<T>(T a, T b);`
  |         |                                    |

- Several member signatures have changed: `Extent.items`, `LinearScale.interpolator`,
  `OrdinalScale.rangePoints`, `OrdinalScale.rangeBands`,
  `OrdinalScale.rangeRoundBands`, `ScaleUtils.extent`, `TimeFormat.multi`:

  |         | Breaking member signature changes |
  |---------|-----------------------------------|
  |         | **Class `Extent`**                |
  | **OLD** | `factory Extent.items(Iterable<T> items, [Comparator compare = Comparable.compare]);`
  | **NEW** | `factory Extent.items(Iterable<T> items, [Comparator<T> compare = Comparable.compare]);`
  |         |                                   |
  |         | **Class `LinearScale`**           |
  | **OLD** | `InterpolatorGenerator interpolator;`
  | **NEW** | `InterpolatorGenerator<num> interpolator;`
  |         |                                   |
  |         | **Class `OrdinalScale`**          |
  | **OLD** | `void rangePoints(Iterable range, [double padding]);`
  | **NEW** | `void rangePoints(Iterable<num> range, [double padding]);`
  |         |                                   |
  | **OLD** | `void rangeBands(Iterable range, [double padding, double outerPadding]);`
  | **NEW** | `void rangeBands(Iterable<num> range, [double padding, double outerPadding]);`
  |         |                                   |
  | **OLD** | `void rangeRoundBands(Iterable range, [double padding, double outerPadding]);`
  | **NEW** | `void rangeRoundBands(Iterable<num> range, [double padding, double outerPadding]);`
  |         |                                   |
  |         | **Class `ScaleUtils`**            |
  | **OLD** | `static Extent extent(Iterable<num> values)`
  | **NEW** | `static Extent<num> extent(Iterable<num> values)`
  |         |                                   |
  |         | **Class `TimeFormat`**            |
  | **OLD** | `TimeFormatFunction multi(List<List> formats)`
  | **NEW** | `FormatFunction multi(List<List> formats)`

- The `charted.core.utils` library's `sum` function's signature changed:

  |         | Breaking library member signature changes |
  |---------|-------------------------------------------|
  |         | **Library `charted.core.utils`**          |
  | **OLD** | `num sum(List values)`
  | **NEW** | `num sum(List<num> values)`

- The signature of the `Extent` class changed:

  |         | Breaking class signature changes |
  |---------|----------------------------------|
  |         | **Class `Extent`**               |
  | **OLD** | `class Extent<T> extends Pair<T, T>`
  | **NEW** | `class Extent<T extends Comparable> extends Pair<T, T>`

## [0.5.0] - 2017-11-16

### Added
- Stacked line renderer for rendering stacked line.

### Changed
- Add type and explicit casting to enable strong mode.

## 0.0.10 - 2015-03-28

### Added
- First release of charted.

[0.5.0]: https://github.com/google/charted/compare/0.0.10...0.5.0
