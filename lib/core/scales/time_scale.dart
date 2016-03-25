//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.scales;

/// TimeScale is a linear scale that operates on time.
class TimeScale extends LinearScale {
  static const _scaleSteps = const [
    1e3, // 1-second
    5e3, // 5-second
    15e3, // 15-second
    3e4, // 30-second
    6e4, // 1-minute
    3e5, // 5-minute
    9e5, // 15-minute
    18e5, // 30-minute
    36e5, // 1-hour
    108e5, // 3-hour
    216e5, // 6-hour
    432e5, // 12-hour
    864e5, // 1-day
    1728e5, // 2-day
    6048e5, // 1-week
    2592e6, // 1-month
    7776e6, // 3-month
    31536e6 // 1-year
  ];

  static final _scaleLocalMethods = [
    [TimeInterval.second, 1],
    [TimeInterval.second, 5],
    [TimeInterval.second, 15],
    [TimeInterval.second, 30],
    [TimeInterval.minute, 1],
    [TimeInterval.minute, 5],
    [TimeInterval.minute, 15],
    [TimeInterval.minute, 30],
    [TimeInterval.hour, 1],
    [TimeInterval.hour, 3],
    [TimeInterval.hour, 6],
    [TimeInterval.hour, 12],
    [TimeInterval.day, 1],
    [TimeInterval.day, 2],
    [TimeInterval.week, 1],
    [TimeInterval.month, 1],
    [TimeInterval.month, 3],
    [TimeInterval.year, 1]
  ];

  static TimeFormatFunction _scaleLocalFormat = new TimeFormat().multi([
    [".%L", (DateTime d) => d.millisecond > 0],
    [":%S", (DateTime d) => d.second > 0],
    ["%I:%M", (DateTime d) => d.minute > 0],
    ["%I %p", (DateTime d) => d.hour > 0],
    ["%a %d", (DateTime d) => (d.weekday % 7) > 0 && d.day != 1],
    ["%b %d", (DateTime d) => d.day != 1],
    ["%B", (DateTime d) => d.month > 1],
    ["%Y", (d) => true]
  ]);

  TimeScale();
  TimeScale._clone(TimeScale source) : super._clone(source);

  @override
  scale(Object val) =>
      super.scale(val is DateTime ? val.millisecondsSinceEpoch : val);

  @override
  set domain(Iterable value) {
    super.domain =
        value.map((d) => d is DateTime ? d.millisecondsSinceEpoch : d).toList();
  }

  @override
  FormatFunction createTickFormatter([String format]) => _scaleLocalFormat;

  @override
  TimeScale clone() => new TimeScale._clone(this);

  List _getTickMethod(Extent extent, int count) {
    var target = (extent.max - extent.min) / count,
        i = ScaleUtils.bisect(_scaleSteps, target);

    return i == _scaleSteps.length
        ? [
            TimeInterval.year,
            _linearTickRange(
                new Extent(extent.min / 31536e6, extent.max / 31536e6)).step
          ]
        : i == 0
            ? [new ScaleMilliSeconds(), _linearTickRange(extent).step]
            : _scaleLocalMethods[target / _scaleSteps[i - 1] <
                _scaleSteps[i] / target ? i - 1 : i];
  }

  List niceInterval(int ticksCount, [int skip = 1]) {
    var extent = ScaleUtils.extent(domain),
        method = _getTickMethod(extent, ticksCount),
        interval;

    if (method != null) {
      interval = method[0];
      skip = method[1];
    }

    bool skipped(var date) {
      if (date is DateTime) date = date.millisecondsSinceEpoch;
      return (interval as TimeInterval).range(date, date + 1, skip).length == 0;
    }

    if (skip > 1) {
      domain = ScaleUtils.nice(
          domain,
          new RoundingFunctions((dateMillis) {
            var date = new DateTime.fromMillisecondsSinceEpoch(dateMillis);
            while (skipped(date = (interval as TimeInterval).floor(date))) {
              date = new DateTime.fromMillisecondsSinceEpoch(
                  date.millisecondsSinceEpoch - 1);
            }
            return date.millisecondsSinceEpoch;
          }, (dateMillis) {
            var date = new DateTime.fromMillisecondsSinceEpoch(dateMillis);
            while (skipped(date = (interval as TimeInterval).ceil(date))) {
              date = new DateTime.fromMillisecondsSinceEpoch(
                  date.millisecondsSinceEpoch + 1);
            }
            return date.millisecondsSinceEpoch;
          }));
    } else {
      domain = ScaleUtils.nice(
          domain,
          new RoundingFunctions(
              (date) => interval.floor(date).millisecondsSinceEpoch,
              (date) => interval.ceil(date).millisecondsSinceEpoch));
    }
    return domain;
  }

  @override
  set nice(bool value) {
    assert(value != null);
    if (value != null && _nice != value) {
      _nice = value;
      domain = niceInterval(_ticksCount);
    }
  }

  List ticksInterval(int ticksCount, [int skip]) {
    var extent = ScaleUtils.extent(domain),
        method = _getTickMethod(extent, ticksCount),
        interval;
    if (method != null) {
      interval = method[0];
      skip = method[1];
    }
    return interval.range(extent.min, extent.max + 1, skip < 1 ? 1 : skip);
  }

  @override
  List get ticks => ticksInterval(ticksCount);
}

class ScaleMilliSeconds implements TimeInterval {
  DateTime _toDateTime(x) {
    assert(x is int || x is DateTime);
    return x is num ? new DateTime.fromMillisecondsSinceEpoch(x) : x;
  }

  DateTime floor(dynamic val) => _toDateTime(val);
  DateTime ceil(dynamic val) => _toDateTime(val);
  DateTime round(dynamic val) => _toDateTime(val);

  DateTime offset(Object val, num dt) {
    assert(val is int || val is DateTime);
    return new DateTime.fromMillisecondsSinceEpoch(
        val is int ? val + dt : (val as DateTime).millisecondsSinceEpoch + dt);
  }

  List<DateTime> range(var t0, var t1, int step) {
    int start = t0 is DateTime ? t0.millisecondsSinceEpoch : t0,
        stop = t1 is DateTime ? t1.millisecondsSinceEpoch : t1;
    return new Range((start / step).ceil() * step, stop, step)
        .map((d) => new DateTime.fromMillisecondsSinceEpoch(d))
        .toList();
  }
}
