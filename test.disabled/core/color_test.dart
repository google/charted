/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.core;

testColor() {
  _checkColorStrings(Color color, String hex, String rgb, String rgba) {
    expect(color.hexString, equals(hex));
    expect(color.rgbString, equals(rgb));
    expect(color.rgbaString, equals(rgba));
  }

  test('Color.fromRgb can be converted to HTML color formats', () {
    _checkColorStrings(new Color.fromRgb(200, 100, 50, 0.5),
        '#c86432', 'rgb(200,100,50)', 'rgba(200,100,50,0.5)');
  });

  group('Color.fromHex', () {
    test('understands strings that start with "#"', () {
      _checkColorStrings(new Color.fromHex('#c86432', 0.5),
          '#c86432', 'rgb(200,100,50)', 'rgba(200,100,50,0.5)');
    });
    test('understands strings that do not start with "#"', () {
      _checkColorStrings(new Color.fromHex('c86432', 0.5),
          '#c86432', 'rgb(200,100,50)', 'rgba(200,100,50,0.5)');
    });
  });

  group('Color.fromColorString', () {
    test('understands strings that start with "#"', () {
      _checkColorStrings(new Color.fromColorString('#c86432'),
          '#c86432', 'rgb(200,100,50)', 'rgba(200,100,50,1.0)');
    });
    test('understands strings with "rgb(r,g,b)" format', () {
      _checkColorStrings(new Color.fromColorString('rgb(200,100,50)'),
          '#c86432', 'rgb(200,100,50)', 'rgba(200,100,50,1.0)');
    });
    test('handles color string not supported', () {
      _checkColorStrings(new Color.fromColorString('hsl(1,1,1)'),
          '#000000', 'rgb(0,0,0)', 'rgba(0,0,0,1.0)');
    });
  });

  group('Color.isColorString', () {
    test('regards strings that start with "#" as color string', () {
      expect(Color.isColorString("#c86432"), isTrue);
    });
    test('regards strings start with "rgb" as color string', () {
      expect(Color.isColorString("rgb(200,100,50)"), isTrue);
    });
    test('does not regard strings start with "hsl" as color string', () {
      expect(Color.isColorString("hsl(1,1,1)"), isFalse);
    });
  });

  test('Color.toString() returns rgb string', () {
    expect(new Color.fromColorString('rgb(200,100,50)').toString(),
        'rgb(200,100,50)');
  });
  
  test('Color.equals()', () {
    var colorA = new Color.fromColorString('rgb(200,100,50)');
    var colorB = new Color.fromColorString('rgb(200,100,50)');
    var colorC = new Color.fromColorString('rgb(10,10,100)');

    expect(colorA, equals(colorB));
    expect(colorA.hashCode, equals(colorB.hashCode));
    expect(colorA != colorC, true);
  });
}
