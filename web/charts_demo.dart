
library charted.demo;

import 'dart:html';
import 'package:charted/charted.dart';

part 'src/dataset_small.dart';
part 'src/dataset_large.dart';

class ChartDemo {
  final List<ChartBehavior> behaviors;
  final ChartConfig config;
  final ChartData data;
  final int dimensionAxesCount;
  final Element host;
  final String title;

  ChartArea area;

  ChartDemo(this.title, this.host, this.config, this.data,
       { this.dimensionAxesCount: 1, this.behaviors: const []}) {
    host.innerHtml =
        '<div class="chart-wrapper">'
        '  <div class="chart-title-wrapper">'
        '     <div class="chart-title">$title</div>'
        '  </div>'
        '  <div class="chart-host-wrapper">'
        '    <div class="chart-host"></div>'
        '    <div class="chart-legend-host"></div>'
        '  </div>'
        '</div>';

    var chartAreaHost = host.querySelector('.chart-host'),
        chartLegendHost = host.querySelector('.chart-legend-host');

    config.legend = new ChartLegend(chartLegendHost);
    area = new ChartArea(chartAreaHost, data, config,
        autoUpdate: false, useTwoDimensionAxes: dimensionAxesCount == 2);
    for (var behavior in behaviors) {
      area.addChartBehavior(behavior);
    }
  }

  void setTheme(ChartTheme theme) {
    area.theme = theme;
  }

  void draw() => area.draw(preRender: data.rows.isEmpty);
}
