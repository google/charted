
library charted.demo.charts.bar_charts;

import "dart:html";
import "package:charted/charts/charts.dart";
import "package:charted/core/utils.dart";
import "../demo_charts.dart";

void drawSimpleBarChart(String selector, ChartState state) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host');

  var series = new ChartSeries("one", [2, 3], new BarChartRenderer()),
      config = new ChartConfig([series], [0]),
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA);

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

void drawHorizontalBarChart(String selector, ChartState state) {
  var wrapper = document.querySelector(selector),
      areaHost = wrapper.querySelector('.chart-host');

  var series = new ChartSeries("one", [2, 3], new BarChartRenderer()),
      config = new ChartConfig([series], [0])
        ..isLeftAxisPrimary = true,
      data = new ChartData(ORDINAL_DATA_COLUMNS, ORDINAL_DATA);

  var area = new CartesianArea(areaHost, data, config, state: state);

  createDefaultCartesianBehaviors().forEach((behavior) {
    area.addChartBehavior(behavior);
  });
  area.draw();
}

main() {
  ChartState singleSelectionState = new ChartState();
  drawSimpleBarChart('#simple-bar-chart', singleSelectionState);
  drawHorizontalBarChart('#horizontal-bar-chart', singleSelectionState);

  document.getElementById('hover').onMouseOver.listen(
      (_) => singleSelectionState.hovered = new Pair(2, 2));
  document.getElementById('hover').onMouseOut.listen(
      (_) => singleSelectionState.hovered = null);

  document.getElementById('highlight').onMouseOver.listen(
      (_) => singleSelectionState.highlight(2, 2));
  document.getElementById('highlight').onMouseOut.listen(
      (_) => singleSelectionState.unhighlight(2, 2));

  document.getElementById('preview').onMouseOver.listen(
      (_) => singleSelectionState.preview = 2);
  document.getElementById('preview').onMouseOut.listen(
      (_) => singleSelectionState.preview = null);

  document.getElementById('select').onMouseOver.listen(
          (_) => singleSelectionState.select(2));
  document.getElementById('select').onMouseOut.listen(
          (_) => singleSelectionState.unselect(2));
}

