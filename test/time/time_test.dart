/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.time;

import 'package:charted/time/time.dart';
import 'package:unittest/unittest.dart';

timeTests() {
  List granularity = [
    ['second', Time.second],
    ['minute', Time.minute],
    ['hour',   Time.hour],
    ['day',    Time.day],
    ['week',   Time.week],
    ['month',  Time.month],
    ['year',   Time.year],
  ];

  DateTime date = new DateTime(2014, 7, 21, 0, 32, 30, 345);
  List mockDate = [
    /* Second */
    [new DateTime(2014, 7, 21, 0, 32, 30),         // floor
     new DateTime(2014, 7, 21, 0, 32, 31),         // ceil
     new DateTime(2014, 7, 21, 0, 32, 30),         // round
     new DateTime(2014, 7, 21, 0, 32, 31, 345)     // offset 1
    ],
    /* Minute */
    [new DateTime(2014, 7, 21, 0, 32),             // floor
     new DateTime(2014, 7, 21, 0, 33),             // ceil
     new DateTime(2014, 7, 21, 0, 33),             // round
     new DateTime(2014, 7, 21, 0, 33, 30, 345)     // offset 1
    ],
    /* Hour */
    [new DateTime(2014, 7, 21, 0),                 // floor
     new DateTime(2014, 7, 21, 1),                 // ceil
     new DateTime(2014, 7, 21, 1),                 // round
     new DateTime(2014, 7, 21, 1, 32, 30, 345)     // offset 1
    ],
    /* Day */
    [new DateTime(2014, 7, 21),                    // floor
     new DateTime(2014, 7, 22),                    // ceil
     new DateTime(2014, 7, 21),                    // round
     new DateTime(2014, 7, 22, 0, 32, 30, 345)     // offset 1
    ],
    /* Week */
    [new DateTime(2014, 7, 21),                    // floor
     new DateTime(2014, 7, 28),                    // ceil
     new DateTime(2014, 7, 21),                    // round
     new DateTime(2014, 7, 28, 0, 32, 30, 345)     // offset 1
    ],
    /* Month */
    [new DateTime(2014, 7),                        // floor
     new DateTime(2014, 8),                        // ceil
     new DateTime(2014, 8),                        // round
     new DateTime(2014, 8, 21, 0, 32, 30, 345)     // offset 1
    ],
    /* Year */
    [new DateTime(2014),                           // floor
     new DateTime(2015),                           // ceil
     new DateTime(2015),                           // round
     new DateTime(2015, 7, 21, 0, 32, 30, 345)     // offset 1
    ],
  ];

  for (var i = 0; i < granularity.length; i++) {
    test('Time.${granularity[i][0]} returns a [TimeInterval] '
         'with ${granularity[i][0]} granularity', () {
      expect(granularity[i][1].floor(date)
          .compareTo(mockDate[i][0]), equals(0));
      expect(granularity[i][1].ceil(date)
          .compareTo(mockDate[i][1]), equals(0));
      expect(granularity[i][1].round(date)
          .compareTo(mockDate[i][2]), equals(0));
      expect(granularity[i][1].offset(date, 1)
          .compareTo(mockDate[i][3]), equals(0));
    });
  }

  test('Time.second.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.second.range(
        new DateTime(2014, 1, 1, 0, 0, 0, 123),
        new DateTime(2014, 1, 1, 0, 0, 20), 5);
    expect(range.length, equals(3));
    expect(range[0].compareTo(new DateTime(2014, 1, 1, 0, 0, 5)), equals(0));
    expect(range[1].compareTo(new DateTime(2014, 1, 1, 0, 0, 10)), equals(0));
    expect(range[2].compareTo(new DateTime(2014, 1, 1, 0, 0, 15)), equals(0));
  });

  test('Time.minute.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.minute.range(
        new DateTime(2014, 1, 1, 0, 4, 10),
        new DateTime(2014, 1, 1, 0, 10, 20), 2);
    expect(range.length, equals(3));
    expect(range[0].compareTo(new DateTime(2014, 1, 1, 0, 6)), equals(0));
    expect(range[1].compareTo(new DateTime(2014, 1, 1, 0, 8)), equals(0));
    expect(range[2].compareTo(new DateTime(2014, 1, 1, 0, 10)), equals(0));
  });

  test('Time.hour.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.hour.range(
        new DateTime(2014, 1, 1, 20, 15),
        new DateTime(2014, 1, 2, 2, 10, 20), 2);
    expect(range.length, equals(3));
    expect(range[0].compareTo(new DateTime(2014, 1, 1, 22)), equals(0));
    expect(range[1].compareTo(new DateTime(2014, 1, 2, 0)), equals(0));
    expect(range[2].compareTo(new DateTime(2014, 1, 2, 2)), equals(0));
  });

  test('Time.day.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.day.range(
        new DateTime(2014, 1, 20, 10),
        new DateTime(2014, 1, 29, 15), 3);
    expect(range.length, equals(3));
    expect(range[0].compareTo(new DateTime(2014, 1, 22)), equals(0));
    expect(range[1].compareTo(new DateTime(2014, 1, 25)), equals(0));
    expect(range[2].compareTo(new DateTime(2014, 1, 28)), equals(0));
  });

  test('Time.week.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.week.range(
        new DateTime(2013, 12, 31, 10),
        new DateTime(2014, 1, 29, 15), 1);
    expect(range.length, equals(4));
    expect(range[0].compareTo(new DateTime(2014, 1, 4)), equals(0));
    expect(range[1].compareTo(new DateTime(2014, 1, 11)), equals(0));
    expect(range[2].compareTo(new DateTime(2014, 1, 18)), equals(0));
    expect(range[3].compareTo(new DateTime(2014, 1, 25)), equals(0));
  });

  test('Time.month.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.month.range(
        new DateTime(2013, 12, 31, 10),
        new DateTime(2014, 5, 29, 15), 2);
    expect(range.length, equals(3));
    expect(range[0].compareTo(new DateTime(2014, 1, 1)), equals(0));
    expect(range[1].compareTo(new DateTime(2014, 3, 1)), equals(0));
    expect(range[2].compareTo(new DateTime(2014, 5, 1)), equals(0));
  });

  test('Time.year.range returns a list of [DateTime] nicely stepped', () {
    List range = Time.year.range(
        new DateTime(2013, 12, 31, 10),
        new DateTime(2018, 5, 29, 15), 2);
    expect(range.length, equals(3));
    expect(range[0].compareTo(new DateTime(2014, 1, 1)), equals(0));
    expect(range[1].compareTo(new DateTime(2016, 1, 1)), equals(0));
    expect(range[2].compareTo(new DateTime(2018, 1, 1)), equals(0));
  });
}
