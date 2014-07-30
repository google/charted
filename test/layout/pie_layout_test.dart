/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.layout;

testPieLayout() {
  List mockPieData = [
    [5, 5, 10],
    [0, 0],
    [4],
    [10, 5, 5],       // Case for sorting, results the same as the first case.
  ];
  List mockPieAngle = [
    [[0, PI / 2], [PI / 2, PI], [PI, PI * 2]],
    [[0, 0], [0, 0]],
    [[0, 2 * PI]],
    [[0, PI / 2], [PI / 2, PI], [PI, PI * 2]],
  ];

  group('PieLayout.startAngleCallback', () {
    PieLayout pieLayout = new PieLayout();
    test('= 0 by default', () {
      expect(pieLayout.startAngleCallback(null, 0, null), equals(0));
    });
    PieLayout pieLayout2 = new PieLayout();
    pieLayout2.startAngle = 0.4;
    test('equals the manually set value after set by startAngle setter', () {
      expect(pieLayout2.startAngleCallback(null, 0, null), equals(0.4));
    });
  });

  group('PieLayout.endAngleCallback', () {
    PieLayout pieLayout = new PieLayout();
    test('= 2 * PI by default', () {
      expect(pieLayout.endAngleCallback(null, 0, null), equals(2 * PI));
    });
    PieLayout pieLayout2 = new PieLayout();
    pieLayout2.endAngle = 0.4;
    test('equals the manually set value after set by endAngle setter', () {
      expect(pieLayout2.endAngleCallback(null, 0, null), equals(0.4));
    });
  });

  group('PieLayout.layout', () {
    test('generates a list of SvgArcData object for pie-chart', () {
      PieLayout pieLayout = new PieLayout();
      List slice = pieLayout.layout(mockPieData[0]);
      for (var i = 0; i < 3; ++i) {
        expect(slice[i].startAngle, closeTo(mockPieAngle[0][i][0], EPSILON));
        expect(slice[i].endAngle, closeTo(mockPieAngle[0][i][1], EPSILON));
      }
    });
    test('generates zero-angled slice for total 0 data', () {
      PieLayout pieLayout = new PieLayout();
      List slice = pieLayout.layout(mockPieData[1]);
      for (var i = 0; i < 2; ++i) {
        expect(slice[i].startAngle, closeTo(mockPieAngle[1][i][0], EPSILON));
        expect(slice[i].endAngle, closeTo(mockPieAngle[1][i][1], EPSILON));
      }
    });
    test('generates concentric pie sector for solo non-zero data', () {
      PieLayout pieLayout = new PieLayout();
      List slice = pieLayout.layout(mockPieData[2]);
      expect(slice[0].startAngle, closeTo(mockPieAngle[2][0][0], EPSILON));
      expect(slice[0].endAngle, closeTo(mockPieAngle[2][0][1], EPSILON));
    });
    test('supports sorting data', () {
      PieLayout pieLayout = new PieLayout();
      pieLayout.compare = (num a, num b) => (a - b).ceil();
      List slice = pieLayout.layout(mockPieData[3]);
      for (var i = 0; i < 3; ++i) {
        expect(slice[i].startAngle, closeTo(mockPieAngle[3][i][0], EPSILON));
        expect(slice[i].endAngle, closeTo(mockPieAngle[3][i][1], EPSILON));
      }
    });
  });
}