/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.horizontal_renderers;

import 'dart:html';
import 'package:charted/charts/charts.dart';

import 'charts_demo.dart';

main() {
  var data = new ChartData(SMALL_DATA_COLUMNS, SMALL_DATA);

  // bar chart
  var barSeries = new ChartSeries("one", [2, 3, 1], new BarChartRenderer()),
      barConfig = new ChartConfig([barSeries], [0])
          ..isLeftAxisPrimary = true,
      behavior = [
        new ChartTooltip()
        ],
      barDemo = new ChartDemo('bar chart', querySelector('.bar-chart'),
          barConfig, data, chartBehaviors: behavior);
  barDemo.setTheme(new HorizontalPrimaryAxisTheme());
  barDemo.draw();

  // stacked bar chart
  var stacked_barSeries = new ChartSeries("one", [2, 3, 1],
      new StackedBarChartRenderer()),
      stackedBarConfig = new ChartConfig([stacked_barSeries], [0])
          ..isLeftAxisPrimary = true,
      stackedBarDemo = new ChartDemo('stacked bar chart', querySelector(
          '.stacked-bar-chart'), stackedBarConfig, data,
          chartBehaviors: behavior);
  stackedBarDemo.setTheme(new HorizontalPrimaryAxisTheme());
  stackedBarDemo.draw();

}

class HorizontalPrimaryAxisTheme extends QuantumChartTheme {

  ChartAxisTheme get measureAxisTheme =>
      const _HorizontalPrimaryAxisTheme(ChartAxisTheme.FILL_RENDER_AREA, 5);
  ChartAxisTheme get dimensionAxisTheme =>
      const _HorizontalPrimaryAxisTheme(0, 10);
}

class _HorizontalPrimaryAxisTheme implements ChartAxisTheme {
  final axisOuterPadding = 0.1;
  final axisBandInnerPadding = 0.35;
  final axisBandOuterPadding = 0.175;
  final axisTickPadding = 6;
  final axisTickSize;
  final axisTickCount;
  final horizontalAxisAutoResize = false;
  final verticalAxisAutoResize = true;
  final verticalAxisWidth = 100;
  final horizontalAxisHeight = 50;
  final ticksFont = '14px Roboto';
  const _HorizontalPrimaryAxisTheme(this.axisTickSize, this.axisTickCount);
}