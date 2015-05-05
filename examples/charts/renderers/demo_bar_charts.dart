
library charted.demo.charts.bar_charts;

import "dart:html";
import "package:charted/charts/charts.dart";
import "../demo_charts.dart";

void drawSimpleBarChart(String selector, bool grouped) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries(
          "one", grouped ? [2, 3] : [2], new BarChartRenderer()),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost),
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawHorizontalBarChart(String selector, bool grouped) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries(
          "one", grouped ? [2, 3] : [2], new BarChartRenderer()),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost)
        ..isLeftAxisPrimary = true,
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawChartWithNegativeNumbers(String selector, bool grouped) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries(
          "one", grouped ? [2, 3] : [2], new BarChartRenderer()),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost),
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA_WITH_NEGATIVE),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawHorizontalChartWithNegativeNumbers(String selector, bool grouped) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series = new ChartSeries(
          "one", grouped ? [2, 3] : [2], new BarChartRenderer()),
      config = new ChartConfig([series], [0])
        ..legend = new ChartLegend(legendHost)
        ..isLeftAxisPrimary = true,
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA_WITH_NEGATIVE),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

main() {
  drawSimpleBarChart('#simple-bar-chart', false);
  drawHorizontalBarChart('#horizontal-bar-chart', false);
  drawChartWithNegativeNumbers('#simple-with-negative-numbers', false);
  drawHorizontalChartWithNegativeNumbers(
      '#horizontal-with-negative-numbers', false);

  drawSimpleBarChart('#grouped-bar-chart', true);
  drawHorizontalBarChart('#horizontal-grouped-bar-chart', true);
  drawChartWithNegativeNumbers('#grouped-with-negative-numbers', true);
  drawHorizontalChartWithNegativeNumbers(
      '#horizontal-grouped-with-negative-numbers', true);
}

