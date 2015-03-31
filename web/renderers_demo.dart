/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.renderers;

import 'dart:html';
import 'package:charted/charts/charts.dart';

import 'charts_demo.dart';

main() {
  var data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);

  // Bar Chart
  var bar_series = new ChartSeries("one", [2, 3], new BarChartRenderer()),
      bar_config = new ChartConfig([bar_series], [0]),
      bar_demo = new ChartDemo(
          'Bar chart', querySelector('.bar-chart'), bar_config, data);
  bar_demo.draw();

  // Line chart
  var line_series = new ChartSeries("one", [2, 3], new LineChartRenderer()),
      line_config = new ChartConfig([line_series], [0]),
      line_demo = new ChartDemo(
          'Line chart', querySelector('.line-chart'), line_config, data);
  line_demo.draw();

  // Stacked bar chart
  var stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      stacked_config = new ChartConfig([stacked_series], [0]),
      stacked_demo = new ChartDemo('Stacked bar chart',
          querySelector('.stacked-bar-chart'), stacked_config, data);
  stacked_demo.draw();

  // Combo chart
  var combo_bar_series = new ChartSeries("one", [2, 3], new BarChartRenderer()),
      combo_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo_config =
          new ChartConfig([combo_bar_series, combo_line_series], [0]),
      combo_demo = new ChartDemo(
          'Combo chart', querySelector('.combo-chart'), combo_config, data);
  combo_demo.draw();
}
