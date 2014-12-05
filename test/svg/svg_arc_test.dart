/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.svg;

testSvgArc() {

  List mockSvgData = [
    new SvgArcData(null, 0, 0,      0,      0,  100),  // Init sector
    new SvgArcData(null, 0, 0,      0,      50, 100),  // Init donut
    new SvgArcData(null, 0, 0,      2 * PI, 0,  100),  // Whole sector
    new SvgArcData(null, 0, 0,      2 * PI, 50, 100),  // Whole donut
    new SvgArcData(null, 0, 0,      PI / 3, 0,  100),  // Sector start angle 0
    new SvgArcData(null, 0, 0,      PI / 3, 50, 100),  // Slice start angle 0
    new SvgArcData(null, 0, PI / 3, PI,     0,  100),  // Sector start angle > 0
    new SvgArcData(null, 0, PI / 3, PI,     50, 100),  // Slice start angle > 0
  ];

  test('interpolateSvgArcData() returns an InterpolateFn that '
      'correctly interpolates two SvgArcData', () {
    InterpolateFn arcInterpolator =
        interpolateSvgArcData(mockSvgData[5], mockSvgData[6]);
    for (var i = 0; i <= 1; i += 0.2) {
      SvgArcData arcData = arcInterpolator(i);
      expect(arcData.startAngle, closeTo(mockSvgData[5].startAngle * (1 - i) +
          mockSvgData[6].startAngle * i, EPSILON));
      expect(arcData.endAngle, closeTo(mockSvgData[5].endAngle * (1 - i) +
          mockSvgData[6].endAngle * i, EPSILON));
      expect(arcData.innerRadius, closeTo(mockSvgData[5].innerRadius * (1 - i) +
          mockSvgData[6].innerRadius * i, EPSILON));
      expect(arcData.outerRadius, closeTo(mockSvgData[5].outerRadius * (1 - i) +
          mockSvgData[6].outerRadius * i, EPSILON));
    }
  });

  group('SvgArc.innerRadiusCallback', () {
    test('is assigned defaultInnerRadiusCallback by default', () {
      SvgArc svgArc = new SvgArc();
      SelectionCallback<num> callBack = svgArc.innerRadiusCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(e.innerRadius)));
      expect(callBack(null, 0, null), equals(0));
      expect(callBack(new SvgArcData(0, 0, 0, 0, null, 0), 0, null), equals(0));
    });
    test('is assigned to (value) => value when set by value', () {
      SvgArc svgArc = new SvgArc();
      svgArc.innerRadius = 30;
      SelectionCallback<num> callBack = svgArc.innerRadiusCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(30)));
    });
  });

  group('SvgArc.outerRadiusCallback', () {
    test('is assigned defaultOuterRadiusCallback by default', () {
      SvgArc svgArc = new SvgArc();
      SelectionCallback<num> callBack = svgArc.outerRadiusCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(e.outerRadius)));
      expect(callBack(null, 0, null), equals(0));
      expect(callBack(new SvgArcData(0, 0, 0, 0, 0, null), 0, null), equals(0));
    });
    test('is assigned to (value) => value when set by value', () {
      SvgArc svgArc = new SvgArc();
      svgArc.outerRadius = 30;
      SelectionCallback<num> callBack = svgArc.outerRadiusCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(30)));
    });
  });

  group('SvgArc.startAngleCallback', () {
    test('is assigned defaultStartAngleCallback by default', () {
      SvgArc svgArc = new SvgArc();
      SelectionCallback<num> callBack = svgArc.startAngleCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(e.startAngle)));
      expect(callBack(null, 0, null), equals(0));
      expect(callBack(new SvgArcData(0, 0, null, 0, 0, 0), 0, null), equals(0));
    });
    test('is assigned to (value) => value when set by value', () {
      SvgArc svgArc = new SvgArc();
      svgArc.startAngle = 30;
      SelectionCallback<num> callBack = svgArc.startAngleCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(30)));
    });
  });

  group('SvgArc.endAngleCallback', () {
    test('is assigned defaultEndAngleCallback by default', () {
      SvgArc svgArc = new SvgArc();
      SelectionCallback<num> callBack = svgArc.endAngleCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(e.endAngle)));
      expect(callBack(null, 0, null), equals(0));
      expect(callBack(new SvgArcData(0, 0, 0, null, 0, 0), 0, null), equals(0));
    });
    test('is assigned to (value) => value when set by value', () {
      SvgArc svgArc = new SvgArc();
      svgArc.endAngle = 30;
      SelectionCallback<num> callBack = svgArc.endAngleCallback;
      mockSvgData.forEach((e) =>
          expect(callBack(e, 0, null), equals(30)));
    });
  });

  test('SvgArc.centroid calculates the centroid of arc slice', () {
    SvgArc svgArc = new SvgArc();
    List centroid = svgArc.centroid(mockSvgData[0], 0, null);
    expect(centroid[0], closeTo(0, EPSILON));
    expect(centroid[1], closeTo(-50, EPSILON));
    centroid = svgArc.centroid(mockSvgData[2], 0, null);
    expect(centroid[0], closeTo(0, EPSILON));
    expect(centroid[1], closeTo(50, EPSILON));
    centroid = svgArc.centroid(mockSvgData[7], 0, null);
    expect(centroid[0], closeTo(64.9519052838329, EPSILON));
    expect(centroid[1], closeTo(37.5, EPSILON));
  });

  group('SvgArc.path', () {
    test('generates concentric pie sector', () {
      SvgArc svgArc = new SvgArc();
      expect(svgArc.path(mockSvgData[2], 0, null),
          equals('M0,100A100,100 0 1,1 0,-100A100,100 0 1,1 0,100Z'));
    });
    test('generates concentric donut circle', () {
      SvgArc svgArc = new SvgArc();
      expect(svgArc.path(mockSvgData[3], 0, null),
          equals('M0,100A100,100 0 1,1 0,-100A100,100 0 1,1 0,100M0,'
                 '50A50,50 0 1,0 0,-50A50,50 0 1,0 0,50Z'));
    });
    test('correctly generates pie sector', () {
      SvgArc svgArc = new SvgArc();
      expect(svgArc.path(mockSvgData[5], 0, null),
          equals('M6.123233995736766e-15,-100.0A100,100 0 0,1 '
                 '86.60254037844386,-50.0L43.30127018922193,'
                 '-25.0A50,50 0 0,0 3.061616997868383e-15,-50.0Z'));
      expect(svgArc.path(mockSvgData[7], 0, null),
          equals('M86.60254037844386,-50.0A100,100 0 0,1 '
                 '6.123233995736766e-15,100.0L3.061616997868383e-15,'
                 '50.0A50,50 0 0,0 43.30127018922193,-25.0Z'));
    });
    test('correctly generates donut slice', () {
      SvgArc svgArc = new SvgArc();
      expect(svgArc.path(mockSvgData[4], 0, null),
          equals('M6.123233995736766e-15,-100.0A100,100 '
                 '0 0,1 86.60254037844386,-50.0L0,0Z'));
      expect(svgArc.path(mockSvgData[6], 0, null),
          equals('M86.60254037844386,-50.0A100,100 0 0,1 '
                 '6.123233995736766e-15,100.0L0,0Z'));
    });
  });

}