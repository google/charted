/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.renderers;

import 'dart:html';
import 'package:charted/core/text_metrics.dart' as tm;
import 'package:charted/charts/charts.dart';

import 'charts_demo.dart';

var line_demo,
    bar_demo,
    grouped_bar_demo,
    stacked_demo,
    horiz_bar_demo,
    horiz_grouped_bar_demo,
    horiz_stacked_demo,
    combo_demo,
    combo2_demo;

draw_charts(List rows) {
  rows.addAll(SMALL_DATA);
  line_demo.draw();
  bar_demo.draw();
  grouped_bar_demo.draw();
  stacked_demo.draw();
  horiz_bar_demo.draw();
  horiz_grouped_bar_demo.draw();
  horiz_stacked_demo.draw();
  combo_demo.draw();
  combo2_demo.draw();
}

pre_render_charts(ChartData data) {
  // Line chart
  var line_series = new ChartSeries("one", [2, 3], new LineChartRenderer()),
      line_config = new ChartConfig([line_series], [0]);
  line_demo = new ChartDemo(
      'Line chart', querySelector('.line-chart'), line_config, data);

  // Bar chart
  var bar_series = new ChartSeries("one", [2], new BarChartRenderer()),
      bar_config = new ChartConfig([bar_series], [0]);
  bar_demo = new ChartDemo(
      'Bar chart', querySelector('.bar-chart'), bar_config, data);

  // Grouped bar chart
  var grouped_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      grouped_bar_config = new ChartConfig([grouped_bar_series], [0]);
  grouped_bar_demo = new ChartDemo('Group bar chart',
      querySelector('.grouped-bar-chart'), grouped_bar_config, data);

  // Stacked bar chart
  var stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      stacked_config = new ChartConfig([stacked_series], [0]);
  stacked_demo = new ChartDemo('Stacked bar chart',
      querySelector('.stacked-bar-chart'), stacked_config, data);

  // Horizontal bar chart
  var horiz_bar_series =
          new ChartSeries("one", [2], new BarChartRenderer()),
      horiz_bar_config = new ChartConfig([horiz_bar_series], [0])
          ..isLeftAxisPrimary = true;
  horiz_bar_demo = new ChartDemo('Horizontal bar chart',
      querySelector('.horiz-bar-chart'), horiz_bar_config, data);

  // Horizontal grouped bar chart
  var horiz_grouped_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      horiz_grouped_bar_config =
          new ChartConfig([horiz_grouped_bar_series], [0])
              ..isLeftAxisPrimary = true;
  horiz_grouped_bar_demo = new ChartDemo('Horizontal group bar chart',
      querySelector('.horiz-grouped-bar-chart'),
      horiz_grouped_bar_config, data);

  // Horizontal stacked bar chart
  var horiz_stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      horiz_stacked_config = new ChartConfig([horiz_stacked_series], [0])
          ..isLeftAxisPrimary = true;
  horiz_stacked_demo = new ChartDemo(
      'Grouped stacked bar chart',
      querySelector('.horiz-stacked-bar-chart'),
      horiz_stacked_config, data);

  // Combo chart
  var combo_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      combo_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo_config =
          new ChartConfig([combo_bar_series, combo_line_series], [0]);
  combo_demo = new ChartDemo('Combo chart (bar and line)',
      querySelector('.combo-chart'), combo_config, data);

  // Combo chart
  var combo2_bar_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      combo2_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo2_config =
          new ChartConfig([combo2_bar_series, combo2_line_series], [0]);
  combo2_demo = new ChartDemo('Combo chart (stacked and line)',
      querySelector('.combo2-chart'), combo2_config, data);
}

main() {
  var rows = [],
      data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA),
      textMetrics = new tm.TextMetrics(fontStyle: '14px Roboto'),
      pre_rendered = false;

  document.querySelector('#pre-trigger').onClick.listen((_) {
    pre_rendered = true;
    pre_render_charts(data);
  });

  document.querySelector('#trigger').onClick.listen((_) {
    if (!pre_rendered) {
      pre_render_charts(data);
    }
    draw_charts(rows);
  });
}
