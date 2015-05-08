
library charted.demo.charts.bar_charts;

import "dart:html";
import "package:charted/charts/charts.dart";
import "../demo_charts.dart";

void drawSimplePieChart(String selector, bool isDonut) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries("one", [2],
          new PieChartRenderer(innerRadiusRatio: isDonut ? 0.618 : 0)),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost, showValues: true),
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      state = new ChartState();

  var area = new LayoutArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawPieChartWithCount(String selector, bool isDonut, int count) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries("one", [2],
          new PieChartRenderer(
              innerRadiusRatio: isDonut ? 0.618 : 0, maxSliceCount: count)),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost, showValues: true),
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      state = new ChartState();

  var area = new LayoutArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

main() {
  drawSimplePieChart('#simple-pie-chart', false);
  drawSimplePieChart('#simple-donut-chart', true);
  drawPieChartWithCount('#pie-chart-with-count', false, 5);
  drawPieChartWithCount('#donut-chart-with-count', true, 5);
}

