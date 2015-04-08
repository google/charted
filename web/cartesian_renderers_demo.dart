/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.cartesian_renderers;

import 'dart:html';
import 'package:charted/core/text_metrics.dart' as tm;
import 'package:charted/charts/charts.dart';

import 'charts_demo.dart';

draw_charts() {
  // Line chart
  var line_series = new ChartSeries("one", [2, 3], new LineChartRenderer()),
      line_config = new ChartConfig([line_series], [0]),
      line_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Line chart',
      querySelector('.line-chart'), line_config, line_data).draw();

  // Bar chart
  var bar_series = new ChartSeries("one", [2], new BarChartRenderer()),
      bar_config = new ChartConfig([bar_series], [0]),
      bar_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Bar chart',
      querySelector('.bar-chart'), bar_config, bar_data).draw();

  // Grouped bar chart
  var grouped_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      grouped_bar_config = new ChartConfig([grouped_bar_series], [0]),
      grouped_bar_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Group bar chart',
      querySelector('.grouped-bar-chart'),
      grouped_bar_config, grouped_bar_data).draw();

  // Stacked bar chart
  var stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      stacked_config = new ChartConfig([stacked_series], [0]),
      stacked_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Stacked bar chart',
      querySelector('.stacked-bar-chart'), stacked_config, stacked_data)
          .draw();

  // Horizontal bar chart
  var horiz_bar_series =
          new ChartSeries("one", [2], new BarChartRenderer()),
      horiz_bar_config = new ChartConfig([horiz_bar_series], [0])
          ..isLeftAxisPrimary = true,
      horiz_bar_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Horizontal bar chart',
      querySelector('.horiz-bar-chart'), horiz_bar_config,
      horiz_bar_data).draw();

  // Horizontal grouped bar chart
  var horiz_grouped_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      horiz_grouped_bar_config =
          new ChartConfig([horiz_grouped_bar_series], [0])
              ..isLeftAxisPrimary = true,
      horiz_grouped_bar_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Horizontal group bar chart',
      querySelector('.horiz-grouped-bar-chart'),
      horiz_grouped_bar_config, horiz_grouped_bar_data).draw();

  // Horizontal stacked bar chart
  var horiz_stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      horiz_stacked_config = new ChartConfig([horiz_stacked_series], [0])
          ..isLeftAxisPrimary = true,
      horiz_stacked_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Horizontal stacked bar chart',
      querySelector('.horiz-stacked-bar-chart'),
      horiz_stacked_config, horiz_stacked_data).draw();

  // Combo chart
  var combo_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      combo_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo_config =
          new ChartConfig([combo_bar_series, combo_line_series], [0]),
      combo_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Combo chart (bar and line)',
      querySelector('.combo-chart'), combo_config, combo_data).draw();

  // Combo chart
  var combo2_bar_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      combo2_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo2_config =
          new ChartConfig([combo2_bar_series, combo2_line_series], [0]),
      combo2_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Combo chart (stacked and line)',
      querySelector('.combo2-chart'), combo2_config, combo2_data).draw();
/*
  // Bubble chart
  var bubble_series =
          new ChartSeries("one", [2], new BubbleChartRenderer()),
      bubble_config = new ChartConfig([bubble_series], [0, 4]),
      bubble_data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);
  new ChartDemo('Bubble chart',
      querySelector('.bubble-chart'), bubble_config, bubble_data,
      useTwoDimensions: true).draw();
 */
}

main() {
  var textMetrics = new tm.TextMetrics(fontStyle: '14px Roboto');
  draw_charts();
}
