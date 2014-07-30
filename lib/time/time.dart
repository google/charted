/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
/*
 * TODO(songrenchu): Document library
 */
library charted.time;

part 'time_interval.dart';

class Time {
  static TimeInterval second = new TimeInterval(
    (DateTime date) => new DateTime.fromMillisecondsSinceEpoch(
        (date.millisecondsSinceEpoch ~/ 1000) * 1000),
    (DateTime date, num offset) {
      date = new DateTime.fromMillisecondsSinceEpoch(
          date.millisecondsSinceEpoch + offset.toInt() * 1000);
      return date;
    },
    (DateTime date) => date.second
  );

  static TimeInterval minute = new TimeInterval(
    (DateTime date) => new DateTime.fromMillisecondsSinceEpoch(
        (date.millisecondsSinceEpoch ~/ 60000) * 60000),
    (DateTime date, num offset) {
      date = new DateTime.fromMillisecondsSinceEpoch(
          date.millisecondsSinceEpoch + offset.toInt() * 60000);
      return date;
    },
    (DateTime date) => date.minute
  );

  static TimeInterval hour = new TimeInterval(
    (DateTime date) => new DateTime.fromMillisecondsSinceEpoch(
        (date.millisecondsSinceEpoch ~/ 3600000) * 3600000),
    (DateTime date, num offset) {
      date = new DateTime.fromMillisecondsSinceEpoch(
          date.millisecondsSinceEpoch + offset.toInt() * 3600000);
      return date;
    },
    (DateTime date) => date.hour
  );

  static TimeInterval day = new TimeInterval(
    (DateTime date) => new DateTime(date.year, date.month, date.day),
    (DateTime date, num offset) =>
        new DateTime(date.year, date.month, date.day + offset.toInt(),
            date.hour, date.minute, date.second, date.millisecond),
    (DateTime date) => date.day - 1
  );

  // TODO(songrenchu): Implement seven days of a week, now only Sunday as
  // the first day is supported.
  static TimeInterval week = new TimeInterval(
    (DateTime date) =>
        new DateTime(date.year, date.month, date.day - date.day % 7),
    (DateTime date, num offset) =>
        new DateTime(date.year, date.month, date.day + offset.toInt()* 7,
            date.hour, date.minute, date.second, date.millisecond ),
    (DateTime date) {
      var day = year.floor(date).day;
      return (dayOfYear(date) +  day % 7) ~/ 7;
    }
  );

  static TimeInterval month = new TimeInterval(
    (DateTime date) => new DateTime(date.year, date.month, 1),
    (DateTime date, num offset) =>
        new DateTime(date.year, date.month + offset.toInt(), date.day,
            date.hour, date.minute, date.second, date.millisecond),
    (DateTime date) => date.month - 1
  );

  static TimeInterval year = new TimeInterval(
    (DateTime date) => new DateTime(date.year),
    (DateTime date, num offset) =>
        new DateTime(date.year + offset.toInt(), date.month, date.day,
            date.hour, date.minute, date.second, date.millisecond),
    (DateTime date) => date.year
  );

  static Function seconds = second.range,
                  minutes = minute.range,
                  hours = hour.range,
                  days = day.range,
                  weeks = week.range,
                  months = month.range,
                  years = year.range;

  static Function secondsUTC = second.rangeUTC,
                  minutesUTC = minute.rangeUTC,
                  hoursUTC = hour.rangeUTC,
                  daysUTC = day.rangeUTC,
                  weeksUTC = week.rangeUTC,
                  monthsUTC = month.rangeUTC,
                  yearsUTC = year.rangeUTC;

  //TODO: better implementation
  static int dayOfYear(DateTime date) {
    var floorYear = year.floor(date);
    return ((date.millisecondsSinceEpoch - floorYear.millisecondsSinceEpoch -
        (date.timeZoneOffset - floorYear.timeZoneOffset).inMilliseconds * 60000)
        ~/ 86400000);
  }
  //TODO: weekOfYear
}