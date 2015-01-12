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
  var dataWaterfallWithSum = new WaterfallChartData(
      SMALL_WATERFALL_DATA_COLUMNS, SMALL_WATERFALL_DATA_WITH_SUM, [0, 2, 5]);

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

  // Waterfall Chart
  var waterfall_series = new ChartSeries("one", [1, 2],
                                         new WaterfallChartRenderer()),
      waterfall_config = new ChartConfig([waterfall_series], [0]),
      waterfall_demo = new ChartDemo(
          'Waterfall chart', querySelector('.waterfall-chart'),
          waterfall_config, dataWaterfallWithSum);
  waterfall_demo.draw();

  // Combo chart
  var combo_bar_series = new ChartSeries("one", [2, 3], new BarChartRenderer()),
      combo_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo_config =
          new ChartConfig([combo_bar_series, combo_line_series], [0]),
      combo_demo = new ChartDemo(
          'Combo chart', querySelector('.combo-chart'), combo_config, data);
  combo_demo.draw();

  // Pie chart
  var pie_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA.sublist(0, 1)),
      pie_series = new ChartSeries("one", [1, 2, 3], new PieChartRenderer()),
      pie_config = new ChartConfig([pie_series], [0]),
      pie_demo = new ChartDemo('Pie chart with single row',
          querySelector('.pie-chart'), pie_config, pie_data,
          dimensionAxesCount: 0);
  pie_demo.draw();

  // Pie chart with multiple rows
  var multi_pie_data =
          new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA.sublist(0, 3)),
      multi_pie_series =
          new ChartSeries("one", [1, 2, 3], new PieChartRenderer()),
      multi_pie_config = new ChartConfig([multi_pie_series], [0]),
      multi_pie_demo = new ChartDemo('Pie chart with multiple row',
          querySelector('.multi-pie-chart'), multi_pie_config, multi_pie_data,
          dimensionAxesCount: 0);
  multi_pie_demo.draw();
}
