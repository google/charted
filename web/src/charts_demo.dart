
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
        ? new LayoutArea(chartAreaHost, data, config, false)
        : new CartesianArea(chartAreaHost, data, config,
            autoUpdate: false, useTwoDimensionAxes: useTwoDimensions,
            state: state);
    behaviors.forEach((behavior) {
      area.addChartBehavior(behavior);
    });
    area.addChartBehavior(new AxisLabelTooltip());
  }

  void setTheme(ChartTheme theme) {
    area.theme = theme;
  }

  void draw() => area.draw(preRender: data.rows.isEmpty);
}
