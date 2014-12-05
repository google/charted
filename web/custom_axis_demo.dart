/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.custom_axis;

import 'dart:html';
import 'package:charted/charts/charts.dart';
import 'package:charted/scale/scale.dart';

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
  // Default Chart
  var series1 = new ChartSeries("one", [1, 3, 2, 6],
          new StackedBarChartRenderer()),
      data = new ChartData(COLUMNS, DATA),
      config = new ChartConfig([series1], [0]),
      area = new ChartArea(querySelector('.default'),
          data, config, autoUpdate:false, dimensionAxesCount:1);
  area.draw();



  // Chart with custom measure axis with specific domain on the scale.
  var series2 = new ChartSeries("one", [1, 3, 2, 6],
          new StackedBarChartRenderer(),
      // measureAxisId matches the id later used in registerMeasureAxis().
          measureAxisIds: ['fixed_domain']),
      data2 = new ChartData(COLUMNS, DATA),
      config2 = new ChartConfig([series2], [0]);

  // Add custom scale and axis config.
  var scale = new LinearScale();
  scale.domain = [0, 1000];
  var axisConfig = new ChartAxisConfig();
  axisConfig.title = 'Axis title';
  axisConfig.scale = scale;

  config2.registerMeasureAxis('fixed_domain', axisConfig);
  var customAxisChart = new ChartArea(querySelector('.custom-domain'),
          data2, config2, autoUpdate:false, dimensionAxesCount:1);
  customAxisChart.draw();



  // Chart with custom measure axis with specific tick values.
  var series3 = new ChartSeries("one", [1, 3, 2, 6],
      new StackedBarChartRenderer(),
  // measureAxisId matches the id later used in registerMeasureAxis().
      measureAxisIds: ['fixed_ticks']),
  data3 = new ChartData(COLUMNS, DATA),
  config3 = new ChartConfig([series3], [0]);

  // Add custom scale and axis config.
  var scale2 = new LinearScale();
  scale2.domain = [0, 300];
  var axisConfig2 = new ChartAxisConfig();
  axisConfig2.title = 'Axis title';
  axisConfig2.scale = scale2;
  axisConfig2.tickValues = [0, 25, 50, 230, 250];

  config3.registerMeasureAxis('fixed_ticks', axisConfig2);
  var fixedTickValueChart = new ChartArea(querySelector('.custom-ticks'),
          data3, config3, autoUpdate:false, dimensionAxesCount:1);
  fixedTickValueChart.draw();
}
