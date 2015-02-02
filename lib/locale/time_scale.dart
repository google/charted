/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.locale;

class TimeScale extends LinearScale {
  static List _scaleSteps = [
    1e3,    // 1-second
    5e3,    // 5-second
    15e3,   // 15-second
    3e4,    // 30-second
    6e4,    // 1-minute
    3e5,    // 5-minute
    9e5,    // 15-minute
    18e5,   // 30-minute
    36e5,   // 1-hour
    108e5,  // 3-hour
    216e5,  // 6-hour
    432e5,  // 12-hour
    864e5,  // 1-day
    1728e5, // 2-day
    6048e5, // 1-week
    2592e6, // 1-month
    7776e6, // 3-month
    31536e6 // 1-year
  ];

  static List _scaleLocalMethods = [
    [chartTime.Time.second, 1],
    [chartTime.Time.second, 5],
    [chartTime.Time.second, 15],
    [chartTime.Time.second, 30],
    [chartTime.Time.minute, 1],
    [chartTime.Time.minute, 5],
    [chartTime.Time.minute, 15],
    [chartTime.Time.minute, 30],
    [chartTime.Time.hour,   1],
    [chartTime.Time.hour,   3],
    [chartTime.Time.hour,   6],
    [chartTime.Time.hour,   12],
    [chartTime.Time.day,    1],
    [chartTime.Time.day,    2],
    [chartTime.Time.week,   1],
    [chartTime.Time.month,  1],
    [chartTime.Time.month,  3],
    [chartTime.Time.year,   1]
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

  TimeScale([List domain = LinearScale.defaultDomainRange,
      List range = LinearScale.defaultDomainRange,
      interpolators.Interpolator interpolator = interpolators.interpolateNumber,
      bool clamp = false]) : super(domain, range, interpolator, clamp);

  DateTime _timeScaleDate(num t) {
    return new DateTime.fromMillisecondsSinceEpoch(t);
  }

  List _tickMethod(Extent extent, int count) {
    var span  = extent.max - extent.min,
        target = span / count,
        i = ScaleUtil.bisect(_scaleSteps, target);

    return i == _scaleSteps.length ?
        [chartTime.Time.year, linearTickRange(
            [extent.min / 31536e6, extent.max / 31536e6], count)[2]] :
        i == 0 ? [new ScaleMilliSeconds(),
            linearTickRange([extent.min, extent.max], count)[2]] :
        _scaleLocalMethods[target / _scaleSteps[i - 1] <
            _scaleSteps[i] / target ? i - 1 : i];
  }

  /**
   * Given a value x as DateTime or TimeStamp, returns the corresponding value
   * in the output range.
   */
  apply(x){
    return super.apply(x is DateTime ? x.millisecondsSinceEpoch: x);
  }

  /**
   * Returns the value in the input domain x for the corresponding value in the
   * output range y. This represents the inverse mapping from range to domain.
   * If elements in range are not number, the invert function returns null.
   */
  invert(y) {
    return super.invert(y);
  }

  /** Sets the domain of the scale. */
  set domain(List newDomain) {
    assert(newDomain.length > 1);
    super.domain = newDomain.map(
        (d) => d is DateTime ? d.millisecondsSinceEpoch : d).toList();
  }

  Function tickFormat(int ticks, [String format = null]) {
    return _scaleLocalFormat;
  }


  /**
   * Returns an exact copy of this time scale. Changes to this scale will not
   * affect the returned scale, and vice versa.
   **/
  TimeScale copy() => new TimeScale(domain, range, interpolator, clamp);

  List niceInterval(var interval, [int skip = 1]) {
    var extent = _scaleDomainExtent();

    var method = interval == null ? _tickMethod(extent, 10) :
                 interval is int ? _tickMethod(extent, interval) : null;

    if (method != null) {
      interval = method[0];
      skip = method[1];
    }

    bool skipped(var date) {
      if (date is DateTime) date = date.millisecondsSinceEpoch;
      return (interval as chartTime.Interval)
          .range(date, date + 1, skip).length == 0;
    }

    if (skip > 1) {
      domain = scaleNice(domain,
        (date) {
          while (skipped(date = (interval as chartTime.Interval).floor(date))) {
            date = _timeScaleDate(date.millisecondsSinceEpoch - 1);
          }
          return date.millisecondsSinceEpoch;
        },
        (date) {
          while (skipped(date = (interval as chartTime.Interval).ceil(date))) {
            date = _timeScaleDate(date.millisecondsSinceEpoch + 1);
          }
          return date.millisecondsSinceEpoch;
        }
      );
    } else {
      domain = scaleNice(domain,
        (date) => interval.floor(date).millisecondsSinceEpoch,
        (date) => interval.ceil(date).millisecondsSinceEpoch
      );
    }
    return domain;
  }

  void nice([int ticks]) {
    domain = niceInterval(ticks);
  }

  Extent _scaleDomainExtent() {
    var extent = scaleExtent(domain);
    return new Extent(extent[0], extent[1]);
  }

  List ticksInterval(var interval, [int skip = 1]) {
    var extent = _scaleDomainExtent();
    var method = interval == null ? _tickMethod(extent, 10) :
        interval is int ? _tickMethod(extent, interval) :
        [interval, skip];

    if (method != null) {
      interval = method[0];
      skip = method[1];
    }

    return interval.range(extent.min, extent.max + 1, skip < 1 ? 1 : skip);
  }

  List ticks([int ticks = 10]) {
    return ticksInterval(ticks);
  }
}

class ScaleMilliSeconds extends chartTime.Interval {
  DateTime floor(var date) =>
      date is num ? new DateTime.fromMillisecondsSinceEpoch(date) : date;
  DateTime ceil(var date) =>
      date is num ? new DateTime.fromMillisecondsSinceEpoch(date) : date;
  List range(var t0, var t1, int step) {
    int start = t0 is DateTime ? t0.millisecondsSinceEpoch : t0,
        stop = t1 is DateTime ? t1.millisecondsSinceEpoch : t1;
    return new Range((start / step).ceil() * step, stop, step).map(
        (d) => new DateTime.fromMillisecondsSinceEpoch(d)).toList();
  }
}
