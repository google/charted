
library charted.demo.charts.combo_charts;

import "dart:html";
import "package:charted/charts/charts.dart";
import "../demo_charts.dart";

void drawBarLineCombo(String selector, bool grouped) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series1 = new ChartSeries(
          "one", grouped ? [2, 3] : [2], new BarChartRenderer()),
      series2 = new ChartSeries("two", [1], new LineChartRenderer()),
      config = new ChartConfig([series1, series2], [0])
        ..legend = new ChartLegend(legendHost),
      data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawStackedBarLineCombo(String selector) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host'),
      legendHost = wrapper.querySelector('.chart-legend-host');

  var series1 = new ChartSeries(
          "one", [2, 3], new StackedBarChartRenderer()),
      series2 = new ChartSeries("two", [1], new LineChartRenderer()),
      config = new ChartConfig([series1, series2], [0])
        ..legend = new ChartLegend(legendHost),
      data = new ChartData(
          ORDINAL_DATA_COLUMNS, ORDINAL_DATA),
      state = new ChartState();

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

main() {
  drawBarLineCombo('#bar-line-combo-chart', false);
  drawBarLineCombo('#grouped-bar-line-combo-chart', true);
  drawStackedBarLineCombo('#stacked-bar-line-combo-chart');
}
