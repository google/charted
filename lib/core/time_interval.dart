//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.core.time_intervals;

typedef DateTime TimeFloorFunction(DateTime val);
typedef DateTime TimeStepFunction(DateTime val, int offset);
typedef int TimeToNumberFunction(DateTime val);

class TimeInterval {
  TimeFloorFunction _floor;
  TimeStepFunction _step;
  TimeToNumberFunction _number;

  TimeInterval(this._floor, this._step, this._number);

  DateTime floor(dynamic date) {
    assert(date is int || date is DateTime);
    if (date is int) {
      date = new DateTime.fromMillisecondsSinceEpoch(date);
    }
    return _floor(date);
  }

  DateTime round(dynamic date) {
    DateTime d0 = floor(date), d1 = offset(d0, 1);
    int ms = date is int ? date : date.millisecondsSinceEpoch;
    return (ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms)
        ? d0
        : d1;
  }

  DateTime ceil(dynamic date) => offset(floor(date), 1);

  DateTime offset(DateTime date, int k) => _step(date, k);

  Iterable<DateTime> range(dynamic t0, dynamic t1, int dt) {
    assert(t0 is int || t0 is DateTime);
    assert(t1 is int || t1 is DateTime);

    List<DateTime> values = [];
    if (t1 is int) {
      t1 = new DateTime.fromMillisecondsSinceEpoch(t1);
    }

    DateTime time = ceil(t0);
    if (dt > 1) {
      while (time.isBefore(t1)) {
        if ((_number(time) % dt) == 0) {
          values.add(new DateTime.fromMillisecondsSinceEpoch(
              time.millisecondsSinceEpoch));
        }
        time = _step(time, 1);
      }
    } else {
      while (time.isBefore(t1)) {
        values.add(new DateTime.fromMillisecondsSinceEpoch(
            time.millisecondsSinceEpoch));
        time = _step(time, 1);
      }
    }
    return values;
  }

  static TimeInterval second = new TimeInterval(
      (DateTime date) => new DateTime.fromMillisecondsSinceEpoch(
          (date.millisecondsSinceEpoch ~/ 1000) * 1000),
      (DateTime date, int offset) =>
          date = new DateTime.fromMillisecondsSinceEpoch(
              date.millisecondsSinceEpoch + offset * 1000),
      (DateTime date) => date.second);

  static TimeInterval minute = new TimeInterval(
      (DateTime date) => new DateTime.fromMillisecondsSinceEpoch(
          (date.millisecondsSinceEpoch ~/ 60000) * 60000),
      (DateTime date, int offset) =>
          date = new DateTime.fromMillisecondsSinceEpoch(
              date.millisecondsSinceEpoch + offset * 60000),
      (DateTime date) => date.minute);

  static TimeInterval hour = new TimeInterval(
      (DateTime date) => new DateTime.fromMillisecondsSinceEpoch(
          (date.millisecondsSinceEpoch ~/ 3600000) * 3600000),
      (DateTime date, int offset) =>
          date = new DateTime.fromMillisecondsSinceEpoch(
              date.millisecondsSinceEpoch + offset * 3600000),
      (DateTime date) => date.hour);

  static TimeInterval day = new TimeInterval(
      (DateTime date) => new DateTime(date.year, date.month, date.day),
      (DateTime date, int offset) => new DateTime(
          date.year,
          date.month,
          date.day + offset,
          date.hour,
          date.minute,
          date.second,
          date.millisecond),
      (DateTime date) => date.day - 1);

  static TimeInterval week = new TimeInterval(
      (DateTime date) =>
          new DateTime(date.year, date.month, date.day - (date.weekday % 7)),
      (DateTime date, int offset) => new DateTime(
          date.year,
          date.month,
          date.day + offset * 7,
          date.hour,
          date.minute,
          date.second,
          date.millisecond), (DateTime date) {
    var day = year.floor(date).day;
    return (dayOfYear(date) + day % 7) ~/ 7;
  });

  static TimeInterval month = new TimeInterval(
      (DateTime date) => new DateTime(date.year, date.month, 1),
      (DateTime date, num offset) => new DateTime(
          date.year,
          date.month + offset,
          date.day,
          date.hour,
          date.minute,
          date.second,
          date.millisecond),
      (DateTime date) => date.month - 1);

  static TimeInterval year = new TimeInterval(
      (DateTime date) => new DateTime(date.year),
      (DateTime date, num offset) => new DateTime(
          date.year + offset,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
          date.millisecond),
      (DateTime date) => date.year);

  static int dayOfYear(DateTime date) =>
      date.difference(year.floor(date)).inDays;
}
