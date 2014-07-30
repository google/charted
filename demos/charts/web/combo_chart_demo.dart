/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.charts_demo;

import 'dart:html';
import 'package:charted/charts/charts.dart';

List COLUMNS = [
    new ChartColumnSpec(label:'Month', type:ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label:'Precipitation'),
    new ChartColumnSpec(label:'High Temperature'),
    new ChartColumnSpec(label:'Low Temperature'),
    new ChartColumnSpec(label:'Random'),
    new ChartColumnSpec(label:'Extra1'),
    new ChartColumnSpec(label:'Extra2'),
    new ChartColumnSpec(label:'Extra3'),
  ];

List DATA = [
    ['January',  4.50, 27, 46, 1,   20, 23, 1],
    ['February', 4.61, 60, 28, 10,  15, 45, 23],
    ['March',    3.26, 32, 49, 100, 4,  34, 1],
    ['April',    1.46, 63, 49, 30,  34, 89, 3]
  ];

main() {
  var series1 = new ChartSeries("one", [1, 3, 2, 6], new StackedBarChartRenderer()),
      series2 = new ChartSeries("two", [1, 4, 5, 6, 7], new LineChartRenderer()),
      data = new ChartData(COLUMNS, DATA),
      config = new ChartConfig([series1, series2], [0]),
      area = new ChartArea(querySelector('.climate-chart'),
          data, config, autoUpdate:false, dimensionAxesCount:1);

  area.draw();
}
