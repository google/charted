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

import 'src/charts_demo.dart';

List<ChartDemo> charts = [];
Iterable DATA_SOURCE = SMALL_DATA.take(8);

draw_charts() {
  var pie_series = new ChartSeries("one", [2], new PieChartRenderer()),
      pie_config = new ChartConfig([pie_series], [0]),
      pie_data = new ChartData(SMALL_DATA_COLUMNS, DATA_SOURCE),
      pie_demo = new ChartDemo('Pie chart',
          querySelector('.pie-chart'), pie_config, pie_data, isLayout: true);
  charts.add(pie_demo);

  var pie2_series = new ChartSeries("one", [2],
          new PieChartRenderer(maxSliceCount: 4)),
      pie2_config = new ChartConfig([pie2_series], [0]),
      pie2_data = new ChartData(SMALL_DATA_COLUMNS, DATA_SOURCE),
      pie2_demo = new ChartDemo('Pie chart with 4 + 1 slices',
          querySelector('.pie2-chart'), pie2_config, pie2_data, isLayout: true);
  charts.add(pie2_demo);

  var donut_series = new ChartSeries("one", [2],
          new PieChartRenderer(innerRadiusRatio: 0.618, maxSliceCount: 4)),
      donut_config = new ChartConfig([donut_series], [0]),
      donut_data = new ChartData(SMALL_DATA_COLUMNS, DATA_SOURCE),
      donut_demo = new ChartDemo('Pie chart with 4 + 1 slices',
          querySelector('.donut-chart'), donut_config, donut_data, isLayout: true);
  charts.add(donut_demo);

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
    Iterable DATA_SOURCE = isRTL ? SMALL_DATA_RTL : SMALL_DATA;
    charts.forEach((ChartDemo x) {
      x.area.data = new ChartData(SMALL_DATA_COLUMNS, DATA_SOURCE.take(8));
      x.draw();
    });
  });
}
