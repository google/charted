/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.locale;

testNumberFormat() {
  EnUsLocale locale = new EnUsLocale();
  NumberFormat formatter = new NumberFormat(locale);

  group('NumberFormat.format returns a format function that', () {
    test('performs correctly with [[fill]align]', () {
      FormatFunction format1 = formatter.format('d<6');
      expect(format1(123), equals('123ddd'));
      FormatFunction format2 = formatter.format('d>6');
      expect(format2(123), equals('ddd123'));
      FormatFunction format3 = formatter.format('d^6');
      expect(format3(123), equals('dd123d'));
      FormatFunction format4 = formatter.format('d=+6');
      expect(format4(123), equals('+dd123'));
      FormatFunction format5 = formatter.format('06');
      expect(format5(123), equals('000123'));
    });
    test('performs correctly with [sign]', () {
      FormatFunction format1 = formatter.format('+');
      expect(format1(123), equals('+123'));
      expect(format1(0), equals('+0'));
      expect(format1(-123), equals('-123'));
      FormatFunction format2 = formatter.format('-');
      expect(format2(123), equals('-123'));
      expect(format2(0), equals('-0'));
      expect(format2(-123), equals('-123'));
      FormatFunction format3 = formatter.format('');
      expect(format3(123), equals('123'));
      expect(format3(0), equals('0'));
      expect(format3(-123), equals('-123'));
      FormatFunction format4 = formatter.format(' ');
      expect(format4(123), equals(' 123'));
      expect(format4(0), equals(' 0'));
      expect(format4(-123), equals('-123'));
    });
    test('performs correctly with [#]', () {
      FormatFunction format1 = formatter.format('#b');
      expect(format1(123), equals('0b1111011'));
      FormatFunction format2 = formatter.format('#o');
      expect(format2(123), equals('0o173'));
      FormatFunction format3 = formatter.format('#x');
      expect(format3(123), equals('0x7b'));
    });
    test('performs correctly with [,]', () {
      FormatFunction format1 = formatter.format(',');
      expect(format1(123), equals('123'));
      expect(format1(12345), equals('12,345'));
    });
    test('performs correctly with [.precision]', () {
      FormatFunction format1 = formatter.format('.2f');
      expect(format1(123.4), equals('123.40'));
      expect(format1(123.45), equals('123.45'));
      expect(format1(123.4567), equals('123.46'));
    });
    test('performs correctly with other values of [type]', () {
      FormatFunction format1 = formatter.format('d');
      expect(format1(123), equals('123'));
      FormatFunction format2 = formatter.format('e');
      expect(format2(123), equals('1e+2'));
      FormatFunction format4 = formatter.format('g');
      expect(format4(123), equals('1e+2'));
      FormatFunction format5 = formatter.format('c');
      expect(format5(49), equals('1'));
    });
  });
}
