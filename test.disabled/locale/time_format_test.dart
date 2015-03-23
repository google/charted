/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.locale;

testTimeFormat() {
  EnUsLocale locale = new EnUsLocale();

  group('TimeFormat.apply()', () {
    test('correctly applies %a and %A', () {
      TimeFormat format = locale.timeFormat('%a %A');
      expect(format.apply(new DateTime(2014, 3, 9)), equals('Sun Sunday'));
      expect(format.apply(new DateTime(2014, 3, 10)), equals('Mon Monday'));
      expect(format.apply(new DateTime(2014, 3, 15)), equals('Sat Saturday'));
    });
    test('correctly applies %b and %B', () {
      TimeFormat format = locale.timeFormat('%b %B');
      expect(format.apply(new DateTime(2014, 1)), equals('Jan January'));
      expect(format.apply(new DateTime(2014, 2)), equals('Feb February'));
      expect(format.apply(new DateTime(2014, 3)), equals('Mar March'));
    });
    test('correctly applies %c', () {
      TimeFormat format = locale.timeFormat('%c');
      expect(format.apply(new DateTime(2014, 2, 3, 4, 15, 32)),
          equals('Mon Feb 3 04:15:32 2014'));
    });
    test('correctly applies %d', () {
      TimeFormat format = locale.timeFormat('%d');
      expect(format.apply(new DateTime(2014, 2, 3)), equals('03'));
      expect(format.apply(new DateTime(2014, 2, 13)), equals('13'));
    });
    test('correctly applies %e', () {
      TimeFormat format = locale.timeFormat('%e');
      expect(format.apply(new DateTime(2014, 2, 3)), equals('3'));
      expect(format.apply(new DateTime(2014, 2, 13)), equals('13'));
    });
    test('correctly applies %H and %I', () {
      TimeFormat format = locale.timeFormat('%H %I');
      expect(format.apply(new DateTime(2014, 2, 3, 5)), equals('05 05'));
      expect(format.apply(new DateTime(2014, 2, 3, 13)), equals('13 01'));
    });
    test('correctly applies %j', () {
      TimeFormat format = locale.timeFormat('%j');
      expect(format.apply(new DateTime(2014, 1, 1)), equals('001'));
      expect(format.apply(new DateTime(2014, 6, 13)), equals('164'));
      expect(format.apply(new DateTime(2014, 12, 31)), equals('365'));
    });
    test('correctly applies %m', () {
      TimeFormat format = locale.timeFormat('%m');
      expect(format.apply(new DateTime(2014, 3)), equals('03'));
      expect(format.apply(new DateTime(2014, 11)), equals('11'));
    });
    test('correctly applies %M', () {
      TimeFormat format = locale.timeFormat('%M');
      expect(format.apply(new DateTime(2014, 2, 3, 1, 3)), equals('03'));
      expect(format.apply(new DateTime(2014, 2, 3, 1, 59)), equals('59'));
    });
    test('correctly applies %L', () {
      TimeFormat format = locale.timeFormat('%L');
      expect(format.apply(new DateTime(14, 2, 3, 1, 3, 0, 23)), equals('023'));
      expect(format.apply(new DateTime(14, 2, 3, 1, 3, 0, 123)), equals('123'));
    });
    test('correctly applies %p', () {
      TimeFormat format = locale.timeFormat('%p');
      expect(format.apply(new DateTime(2014, 2, 3, 1)), equals('AM'));
      expect(format.apply(new DateTime(2014, 2, 3, 13)), equals('PM'));
    });
    test('correctly applies %S', () {
      TimeFormat format = locale.timeFormat('%S');
      expect(format.apply(new DateTime(2014, 2, 3, 1, 3, 1)), equals('01'));
      expect(format.apply(new DateTime(2014, 2, 3, 1, 3, 23)), equals('23'));
    });
    test('correctly applies %x', () {
      TimeFormat format = locale.timeFormat('%x');
      expect(format.apply(new DateTime(2014, 2, 3)), equals('02/03/2014'));
    });
    test('correctly applies %X', () {
      TimeFormat format = locale.timeFormat('%X');
      expect(format.apply(new DateTime(4, 2, 3, 1, 3, 15)), equals('01:03:15'));
    });
    test('correctly applies %y and %Y', () {
      TimeFormat format = locale.timeFormat('%y %Y');
      expect(format.apply(new DateTime(1904)), equals('04 1904'));
      expect(format.apply(new DateTime(2004)), equals('04 2004'));
      expect(format.apply(new DateTime(2094)), equals('94 2094'));
    });
    test('correctly applies %%', () {
      TimeFormat format = locale.timeFormat('%%');
      expect(format.apply(new DateTime(1904)), equals('%'));
    });
  });

  test('TimeFormat.parse()correctly parses string', () {
    TimeFormat format = locale.timeFormat('%x');
    expect(format.parse("02/03/2014"), new isInstanceOf<DateTime>());
    expect(() => format.parse("2014-02-03"),
        throwsA(new isInstanceOf<FormatException>()));
  });

  var multiFormat = locale.timeFormat().multi([
    [".%L", (d) => (d as DateTime).millisecond > 0],
    [":%S", (d) => (d as DateTime).second > 0],
    ["%Y",  (d) => true]
  ]);

  test('TimeFormat.multi() correctly formats time string', () {
    expect(multiFormat(new DateTime(2014, 1, 1, 1, 1, 3, 123)), equals('.123'));
    expect(multiFormat(new DateTime(2014, 1, 1, 1, 1, 3)), equals(':03'));
    expect(multiFormat(new DateTime(2014)), equals('2014'));
  });

  var iso = TimeFormat.iso();
  test('TimeFormat.iso() correctly formats time string', () {
    expect(iso.apply(new DateTime(2014, 2, 3, 4, 5, 6, 123)),
        equals('2014-02-03T04:05:06.123Z'));
  });

  var utc = locale.timeFormat().utc("%Y-%m-%d %H:%M:%S");
  test('TimeFormat.iso() correctly formats time string', () {
    expect(utc.apply(new DateTime(2014, 2, 3, 4, 5, 6, 123)),
        equals('2014-02-03 04:05:06'));
  });
}
