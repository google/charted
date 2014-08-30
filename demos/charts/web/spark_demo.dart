/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.charts_demo;

import 'dart:html';
import 'package:charted/charts/charts.dart';
import 'package:charted/core/core.dart';

List COLUMNS = [
    new ChartColumnSpec(label:'Month'),
    new ChartColumnSpec(label:'Precipitation'),
  ];

List DATA = [
    [1,  4.50],
    [3,  40.61],
    [5,  3.26],
    [7,  146],
    [9,  4.61],
    [11, 4.50],
    [13, 4.61],
    [15, 326,],
    [17, 1.46],
    [19, 4.61],
    [21, 4.50],
    [23, 4.61],
    [25, 3.26],
    [27, 1.46],
    [29, 4.61],
    [31, 7.50],
    [33, 9.61],
    [35, 11.26],
    [37, 14.46],
    [39, 78.61],
    [41, 89.50],
    [43, 99.61],
    [45, 103.26],
    [47, 111.46],
    [49, 54.61],
    [51, 34.50],
    [61, 4.61],
    [70, 3.26],
    [71, 1.46],
    [72, 4.61],
  ];

main() {
  var element = querySelector('.climate-chart'),
      series = new ChartSeries('one', [1], new LineChartRenderer()),
      data = new ChartData(COLUMNS, DATA),
      config = new ChartConfig([series], [0])
          ..displayedMeasureAxes = []
          ..renderDimensionAxes = false
          ..minimumSize = new Rect.size(100,50),
      area = new ChartArea(element, data, config, dimensionAxesCount:1);
  area.draw();
}
