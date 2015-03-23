/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.scale;

testTimeScale() {
  List mockTimes = [
    // 0: differ in milliseconds
    new DateTime(2014, 1,  3,  0,  2,  3,  0),
    new DateTime(2014, 1,  3,  0,  2,  3,  125),
    new DateTime(2014, 1,  3,  0,  2,  3,  890),
    // 3: differ in seconds:
    new DateTime(2014, 1,  3,  0,  2,  3),
    new DateTime(2014, 1,  3,  0,  2,  4),
    new DateTime(2014, 1,  3,  0,  2,  10, 10),
    // 6: differ in minutes:
    new DateTime(2014, 1,  3,  0,  3,  4),
    new DateTime(2014, 1,  3,  0,  5,  30),
    new DateTime(2014, 1,  3,  0,  20, 31, 23),
    // 9: differ in hours:
    new DateTime(2014, 1,  3,  1,  2,  13),
    new DateTime(2014, 1,  3,  5,  25, 3),
    new DateTime(2014, 1,  3,  23, 45, 43, 100),
    // 12: differ in days:
    new DateTime(2014, 1,  5,  2,  1,  23, 200),
    new DateTime(2014, 1,  14, 10, 0,  3,  25),
    new DateTime(2014, 1,  30, 20, 32, 33),
    // 15: differ in months:
    new DateTime(2014, 2,  13, 3,  48, 53),
    new DateTime(2014, 6,  8,  6,  25, 13),
    new DateTime(2014, 12, 20, 20, 17, 3, 400),
    // 18: differ in years:
    new DateTime(2015, 3,  8,  23, 23, 6),
    new DateTime(2017, 8,  23, 1,  10, 4, 100),
    new DateTime(2044, 1,  5,  0,  9,  8, 100),
  ];


  test('TimeScale.nice() extends domain boundary elements to nice values', () {
    TimeScale timeScale = new TimeScale();
    timeScale.domain = [mockTimes[0], mockTimes[8]];
    timeScale.nice();
    expect(timeScale.domain, orderedEquals([
        new DateTime(2014, 1, 3, 0, 2).millisecondsSinceEpoch,
        new DateTime(2014, 1, 3, 0, 21).millisecondsSinceEpoch
    ]));
    timeScale.domain = [mockTimes[1], mockTimes[10]];
    timeScale.nice();
    expect(timeScale.domain, orderedEquals([
        new DateTime(2014, 1, 3).millisecondsSinceEpoch,
        new DateTime(2014, 1, 3, 5, 30).millisecondsSinceEpoch
    ]));
    timeScale.domain = [mockTimes[13], mockTimes[19]];
    timeScale.nice(5);
    expect(timeScale.domain, orderedEquals([
        new DateTime(2014, 1).millisecondsSinceEpoch,
        new DateTime(2018, 1).millisecondsSinceEpoch
    ]));
  });

  test('TimeScale.niceInterval() extends domain to nice values', () {
    TimeScale timeScale = new TimeScale();
    timeScale.domain = [mockTimes[2], mockTimes[11]];
    timeScale.niceInterval(1, 3);
    expect(timeScale.domain, orderedEquals([
        new DateTime(2014, 1, 3).millisecondsSinceEpoch,
        new DateTime(2014, 1, 4).millisecondsSinceEpoch
    ]));
    timeScale.domain = [mockTimes[5], mockTimes[6]];
    timeScale.niceInterval(5, 2);
    expect(timeScale.domain, orderedEquals([
        new DateTime(2014, 1, 3, 0, 2).millisecondsSinceEpoch,
        new DateTime(2014, 1, 3, 0, 3, 15).millisecondsSinceEpoch
    ]));
    timeScale.domain = [mockTimes[14], mockTimes[18]];
    timeScale.niceInterval(16, 3);
    expect(timeScale.domain, orderedEquals([
        new DateTime(2014, 1, 1).millisecondsSinceEpoch,
        new DateTime(2015, 4, 1).millisecondsSinceEpoch
    ]));
  });

  test('TimeScale.ticks() returns correct tick values', () {
    TimeScale timeScale = new TimeScale();
    timeScale.domain = [mockTimes[3], mockTimes[9]];
    expect(timeScale.ticks(3), orderedEquals([
        new DateTime(2014, 1, 3, 0, 15),
        new DateTime(2014, 1, 3, 0, 30),
        new DateTime(2014, 1, 3, 0, 45),
        new DateTime(2014, 1, 3, 1, 0)
    ]));
    timeScale.domain = [mockTimes[4], mockTimes[15]];
    expect(timeScale.ticks(5), orderedEquals([
        new DateTime(2014, 1, 7),
        new DateTime(2014, 1, 14),
        new DateTime(2014, 1, 21),
        new DateTime(2014, 1, 28),
        new DateTime(2014, 2, 4),
        new DateTime(2014, 2, 11)
    ]));
    timeScale.domain = [mockTimes[7], mockTimes[19]];
    expect(timeScale.ticks(3), orderedEquals([
        new DateTime(2015, 1, 1),
        new DateTime(2016, 1, 1),
        new DateTime(2017, 1, 1)
    ]));
  });

  test('TimeScale.ticksInterval() returns correct tick values', () {
    TimeScale timeScale = new TimeScale();
    timeScale.domain = [mockTimes[0], mockTimes[12]];
    expect(timeScale.ticksInterval(3, 2), orderedEquals([
        new DateTime(2014, 1, 3, 12),
        new DateTime(2014, 1, 4),
        new DateTime(2014, 1, 4, 12),
        new DateTime(2014, 1, 5)
    ]));
    timeScale.domain = [mockTimes[16], mockTimes[17]];
    expect(timeScale.ticksInterval(7, 10), orderedEquals([
        new DateTime(2014, 7, 1),
        new DateTime(2014, 8, 1),
        new DateTime(2014, 9, 1),
        new DateTime(2014, 10, 1),
        new DateTime(2014, 11, 1),
        new DateTime(2014, 12, 1)
    ]));
    timeScale.domain = [mockTimes[13], mockTimes[20]];
    expect(timeScale.ticksInterval(2, 5), orderedEquals([
        new DateTime(2020, 1, 1),
        new DateTime(2040, 1, 1)
    ]));
  });

}
