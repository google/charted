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

String formatter(num x) {
  return x.toInt().toString() + 'kg';
}

List COLUMNS = [
    new ChartColumnSpec(label:'Month',
        type:ChartColumnSpec.TYPE_NUMBER, formatter: formatter),
    new ChartColumnSpec(label:'Precipitation'),
    new ChartColumnSpec(label:'High Temperature'),
    new ChartColumnSpec(label:'Low Temperature')
  ];

List DATA = [
    [1,  4.50, 57, 46],
    [3,  40.61, 60, 48],
    [5,  3.26, 62, 49],
    [7,  146, 63, 49],
    [9,  4.61, 60, 48],
    [11, 4.50, 57, 46],
    [13, 4.61, 60, 48],
    [15, 326, 62, 49],
    [17, 1.46, 63, 49],
    [19, 4.61, 60, 48],
    [21, 4.50, 57, 46],
    [23, 4.61, 60, 48],
    [25, 3.26, 62, 49],
    [27, 1.46, 63, 49],
    [29, 4.61, 60, 48],
    [31, 4.50, 57, 46],
    [33, 4.61, 60, 48],
    [35, 3.26, 62, 49],
    [37, 1.46, 63, 49],
    [39, 4.61, 60, 48],
    [41, 4.50, 57, 46],
    [43, 4.61, 60, 48],
    [45, 3.26, 62, 49],
    [47, 1.46, 63, 49],
    [49, 4.61, 60, 48],
    [51, 4.50, 57, 46],
    [153, 4.61, 60, 48],
    [155, 3.26, 62, 49],
    [257, 1.46, 63, 49],
    [259, 4.61, 60, 48],
  ];

main() {
  var series = new ChartSeries('one', [1, 2, 3], new LineChartRenderer()),
      data = new ChartData(COLUMNS, DATA),
      config = new ChartConfig([series], [0], dimensionTickNumbers: [3]),
      area = new ChartArea(querySelector('.climate-chart'),
          data, config, autoUpdate:false, dimensionAxesCount:1);
  area.draw();
}
