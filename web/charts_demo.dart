
library charted.demo;

import 'dart:html';
import 'package:charted/charted.dart';

part 'src/dataset_small.dart';
part 'src/dataset_large.dart';

class ChartDemo {
  final List<ChartBehavior> chartBehaviors;
  final ChartConfig config;
  final ChartData data;
  final int dimensionAxesCount;
  final Element host;
  final String title;

  ChartArea area;

  ChartDemo(this.title, this.host, this.config, this.data,
       { this.dimensionAxesCount: 1, this.chartBehaviors: const []}) {
    var chartAreaHost = new DivElement()..classes.add('chart-host'),
        chartLegendHost = new DivElement()..classes.add('legend-host'),
        wrapper = new DivElement()
            ..children.addAll([chartAreaHost, chartLegendHost])
            ..classes.add('chart-wrapper');

    host.children.addAll(
        [ new Element.html('<div><h2>$title</h2></div>'), wrapper ]);

    config.legend = new ChartLegend(chartLegendHost);
    area = new ChartArea(chartAreaHost, data, config,
        autoUpdate: false, dimensionAxesCount: dimensionAxesCount);
    for (var behavior in chartBehaviors) {
      area.addChartBehavior(behavior);
    }
  }

  void draw() => area.draw();
}
