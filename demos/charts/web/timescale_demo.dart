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

String formatter(num x) {
  return x.toInt().toString() + 'kg';
}

List COLUMNS = [
    new ChartColumnSpec(label:'Month',
        type:ChartColumnSpec.TYPE_DATE),
    new ChartColumnSpec(label:'Precipitation'),
    new ChartColumnSpec(label:'High Temperature'),
    new ChartColumnSpec(label:'Low Temperature')
  ];

List DATA = [
    [new DateTime(2011, 1, 1, 0, 0, 0, 0), 10, 10, 70],
    [new DateTime(2011, 1, 2, 0, 0, 0,1), 30, 10, 50],
    [new DateTime(2011, 1, 3, 0, 0, 0,3), 20, 10, 60],
    [new DateTime(2011, 1, 4, 0, 0, 0,10), 40, 10, 40],
    [new DateTime(2011, 1, 5, 0, 0, 0,20), 60, 10, 20],
    [new DateTime(2011, 1, 6, 0, 0, 0,30), 50, 10, 30],
    [new DateTime(2011, 1, 7, 0, 0, 0,35), 70, 10, 10],
  ];

main() {
  var series = new ChartSeries('one', [1, 2, 3], new LineChartRenderer()),
      data = new ChartData(COLUMNS, DATA),
      config = new ChartConfig([series], [0]),
      area = new ChartArea(querySelector('.climate-chart'),
          data, config, autoUpdate:false, dimensionAxesCount:1);
  area.draw();
}
