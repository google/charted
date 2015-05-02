
library charted.demo.charts.line_charts;

import "dart:html";
import "package:charted/charts/charts.dart";
import "../demo_charts.dart";

void drawOrdinalLineChart(String selector) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries("one", [2, 3] , new LineChartRenderer()),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost),
      data = new ChartData(
          ORDINAL_SMALL_DATA_COLUMNS, ORDINAL_SMALL_DATA),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawTimeSeriesChart(String selector) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries("one", [2, 3], new LineChartRenderer()),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost),
      data = new ChartData(
          ORDINAL_SMALL_DATA_COLUMNS, ORDINAL_SMALL_DATA),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawOrdinalWithNegative(String selector) {
}

void drawTimeSeriesWithNegative(String selector) {
}

main() {
  drawOrdinalLineChart('#ordinal-line-chart');
  drawOrdinalWithNegative('#ordinal-with-negative');
  drawTimeSeriesChart('#time-series-chart');
  drawTimeSeriesWithNegative('#time-series-with-negative');
}

