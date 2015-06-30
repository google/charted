/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.charts.cartesian_renderers;

import 'dart:html';
import 'package:charted/core/text_metrics.dart' as tm;
import 'package:charted/charts/charts.dart';

import '../demo_charts.dart';

List<ChartDemo> charts = [];

class ChartDemo {
  final List<ChartBehavior> behaviors;
  final ChartConfig config;
  final ChartData data;
  final bool useTwoDimensions;
  final Element host;
  final String title;
  final bool isLayout;

  ChartArea area;

  ChartDemo(this.title, this.host, this.config, this.data,
            { this.useTwoDimensions: false, this.behaviors: const [],
            this.isLayout: false }) {
    var wrapper = document.createElement('div')..className = "chart-wrapper",
        titleWrap = document.createElement('div')
          ..className = "chart-title-wrapper",
        titleContainer = document.createElement('div')
          ..className = 'chart-title'
          ..text = title,
        chartHostWrapper =
            document.createElement('div')..className = "chart-host-wrapper",
        chartAreaHost = document.createElement('div')
          ..className = "chart-host"
          ..attributes['dir'] = 'ltr',
        chartLegendHost =
            document.createElement('div')..className = "chart-legend-host",
        state = new ChartState();

    titleWrap.append(titleContainer);
    chartHostWrapper
      ..append(chartAreaHost)
      ..append(chartLegendHost);
    wrapper
      ..append(titleWrap)
      ..append(chartHostWrapper);
    host.append(wrapper);

    config.legend = new ChartLegend(chartLegendHost, showValues: isLayout);
    area = isLayout
        ? new LayoutArea(chartAreaHost, data, config, state: state)
        : new CartesianArea(chartAreaHost, data, config,
            autoUpdate: false, useTwoDimensionAxes: useTwoDimensions,
            state: state);

    behaviors.forEach((behavior) {
      area.addChartBehavior(behavior);
    });

    area.addChartBehavior(new Hovercard(isMultiValue: true));
    if (!isLayout) {
      area.addChartBehavior(new AxisLabelTooltip());
    }
  }

  void setTheme(ChartTheme theme) {
    area.theme = theme;
  }

  void draw() => area.draw(preRender: data.rows.isEmpty);
}

draw_charts() {
  // Line chart
  var line_series = new ChartSeries("one", [2, 3], new LineChartRenderer()),
      line_config = new ChartConfig([line_series], [0]),
      line_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      line_demo = new ChartDemo('Line chart',
          querySelector('.line-chart'), line_config, line_data);
  charts.add(line_demo);

  // Bar chart
  var bar_series = new ChartSeries("one", [2], new BarChartRenderer()),
      bar_config = new ChartConfig([bar_series], [0]),
      bar_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      bar_demo = new ChartDemo('Bar chart',
          querySelector('.bar-chart'), bar_config, bar_data);
  charts.add(bar_demo);

  // Grouped bar chart
  var grouped_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      grouped_bar_config = new ChartConfig([grouped_bar_series], [0]),
      grouped_bar_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      grouped_bar_demo = new ChartDemo('Group bar chart',
          querySelector('.grouped-bar-chart'),
          grouped_bar_config, grouped_bar_data);
  charts.add(grouped_bar_demo);

  // Stacked bar chart
  var stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      stacked_config = new ChartConfig([stacked_series], [0]),
      stacked_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      stacked_demo = new ChartDemo('Stacked bar chart',
          querySelector('.stacked-bar-chart'), stacked_config, stacked_data);
  charts.add(stacked_demo);

  // Horizontal bar chart
  var horiz_bar_series =
          new ChartSeries("one", [2], new BarChartRenderer()),
      horiz_bar_config = new ChartConfig([horiz_bar_series], [0])
          ..isLeftAxisPrimary = true,
      horiz_bar_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      horiz_bar_demo = new ChartDemo('Horizontal bar chart',
          querySelector('.horiz-bar-chart'), horiz_bar_config,
          horiz_bar_data);
  charts.add(horiz_bar_demo);

  // Horizontal grouped bar chart
  var horiz_grouped_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      horiz_grouped_bar_config =
          new ChartConfig([horiz_grouped_bar_series], [0])
              ..isLeftAxisPrimary = true,
      horiz_grouped_bar_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      horiz_grouped_bar_demo = new ChartDemo('Horizontal group bar chart',
          querySelector('.horiz-grouped-bar-chart'),
          horiz_grouped_bar_config, horiz_grouped_bar_data);
  charts.add(horiz_grouped_bar_demo);

  // Horizontal stacked bar chart
  var horiz_stacked_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      horiz_stacked_config = new ChartConfig([horiz_stacked_series], [0])
          ..isLeftAxisPrimary = true,
      horiz_stacked_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      horiz_stacked_demo = new ChartDemo('Horizontal stacked bar chart',
          querySelector('.horiz-stacked-bar-chart'),
          horiz_stacked_config, horiz_stacked_data);
  charts.add(horiz_stacked_demo);

  // Combo chart
  var combo_bar_series =
          new ChartSeries("one", [2, 3], new BarChartRenderer()),
      combo_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo_config =
          new ChartConfig([combo_bar_series, combo_line_series], [0]),
      combo_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      combo_demo = new ChartDemo('Combo chart - bar and line',
          querySelector('.combo-chart'), combo_config, combo_data);
  charts.add(combo_demo);

  // Combo chart
  var combo2_bar_series =
          new ChartSeries("one", [2, 3], new StackedBarChartRenderer()),
      combo2_line_series = new ChartSeries("two", [1], new LineChartRenderer()),
      combo2_config =
          new ChartConfig([combo2_bar_series, combo2_line_series], [0]),
      combo2_data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      combo2_demo = new ChartDemo('Combo chart - stacked and line',
          querySelector('.combo2-chart'), combo2_config, combo2_data);
  charts.add(combo2_demo);

  charts.forEach((ChartDemo x) => x.draw());
}

main() {
  new tm.TextMetrics(fontStyle: '14px Roboto');
  draw_charts();

  Element chartsContainer = querySelector('.demos-container');
  InputElement useRTLScriptCheckBox = querySelector('#rtl-use-script'),
      switchAxesForRTLCheckBox = querySelector('#rtl-switch-axes'),
      useRTLLayoutCheckBox = querySelector('#rtl-use-layout');

  useRTLLayoutCheckBox.onChange.listen((_) {
    bool isRTL = useRTLLayoutCheckBox.checked;
    charts.forEach((ChartDemo x) => x.config.isRTL = isRTL);
    chartsContainer.attributes['dir'] = isRTL ? 'rtl' : 'ltr';
  });

  useRTLScriptCheckBox.onChange.listen((_) {
    bool isRTL = useRTLScriptCheckBox.checked;
    Iterable DATA_SOURCE = isRTL
        ? ORDINAL_DATA_RTL
        : ORDINAL_DATA;
    charts.forEach((ChartDemo x) {
      x.area.data = new ChartData(ORDINAL_DATA_COLUMNS, DATA_SOURCE);
      x.draw();
    });
  });
}
