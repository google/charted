/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.interactive_renderers;

import 'dart:html';
import 'package:charted/charts/charts.dart';

import 'charts_demo.dart';

main() {
  var data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);

  // Line chart
  var line_series = new ChartSeries("one", [3, 1], new LineChartRenderer()),
      line_series2 = new ChartSeries("two", [2], new LineChartRenderer()),
      line_config = new ChartConfig([line_series, line_series2], [0]),
      behavior = [
        new ChartTooltip(showSelectedMeasure: true)
        ],
      line_demo = new ChartDemo('Line chart', querySelector('.line-chart'),
          line_config, data, chartBehaviors: behavior);
  line_demo.draw();

}
