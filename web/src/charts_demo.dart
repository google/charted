
library charted.demo;

import 'dart:html';
import 'package:charted/charted.dart';

part 'dataset_small.dart';
part 'dataset_large.dart';

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
    host.innerHtml =
        '<div class="chart-wrapper">'
        '  <div class="chart-title-wrapper">'
        '     <div class="chart-title">$title</div>'
        '  </div>'
        '  <div class="chart-host-wrapper">'
        '    <div class="chart-host" dir="ltr"></div>'
        '    <div class="chart-legend-host"></div>'
        '  </div>'
        '</div>';

    var chartAreaHost = host.querySelector('.chart-host'),
        chartLegendHost = host.querySelector('.chart-legend-host'),
        state = new ChartState();

    config.legend = new ChartLegend(chartLegendHost, showValues: isLayout);
    area = isLayout
        ? new LayoutArea(chartAreaHost, data, config, false)
        : new CartesianArea(chartAreaHost, data, config,
            autoUpdate: false, useTwoDimensionAxes: useTwoDimensions,
            state: state);
    for (var behavior in behaviors) {
      area.addChartBehavior(behavior);
    }
  }

  void setTheme(ChartTheme theme) {
    area.theme = theme;
  }

  void draw() => area.draw(preRender: data.rows.isEmpty);
}
