/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.svg;

testSvgLine() {

  List mockSvgData = [
    [1, 2], [2, 1.5], [4, 8], [4.5, 2], [10, 2], [11, 5],
  ];

  group('SvgLine.xAccessor', () {
    SvgLine svgLine = new SvgLine();
    test('is set to defaultDataToX by default', () {
      mockSvgData.forEach((e) => expect(svgLine.xAccessor(e, 0), equals(e[0])));
    });
    test('is set to a constant value as the x-value for all points', () {
      svgLine.x = 3;
      mockSvgData.forEach((e) => expect(svgLine.xAccessor(e, 0), equals(3)));
    });
  });

  group('SvgLine.yAccessor', () {
    SvgLine svgLine = new SvgLine();
    test('is set to defaultDataToY by default', () {
      mockSvgData.forEach((e) => expect(svgLine.yAccessor(e, 0), equals(e[1])));
    });
    test('is set to a constant value as the y-value for all points', () {
      svgLine.y = 3;
      mockSvgData.forEach((e) => expect(svgLine.yAccessor(e, 0), equals(3)));
    });
  });

  group('SvgLine.path', () {
    SvgLine svgLine = new SvgLine();
    test('generates one line path by default', () {
      expect(svgLine.path(mockSvgData, 0, null),
          equals('M1,2L2,1.5L4,8L4.5,2L10,2L11,5'));
    });
    test('generates several line segments if some points are not valid', () {
      svgLine.defined = (d, i, e) => i != 3;  // The fourth point is not valid.
      expect(svgLine.path(mockSvgData, 0, null),
          equals('M1,2L2,1.5L4,8M10,2L11,5'));
      svgLine.defined = (d, i, e) => i == 1;  // Only the second point is valid.
      expect(svgLine.path(mockSvgData, 0, null), equals('M2,1.5'));
    });
  });

}