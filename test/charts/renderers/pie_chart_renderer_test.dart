library charted.test.piechartrenderer;

import 'dart:async';
import 'dart:html';

import 'package:charted/charts/charts.dart';
import 'package:charted/core/core.dart';
import 'package:charted/layout/layout.dart';
import 'package:charted/svg/svg.dart';
import 'package:unittest/unittest.dart';

main() {
  const CHART_WIDTH = 1000;
  const CHART_HEIGHT = 400;

  List COLUMNS = [
    new ChartColumnSpec(label:'Country', type:ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label:'statsList1'),
    new ChartColumnSpec(label:'statsList2'),
    new ChartColumnSpec(label:'statsList3')
  ];

  const List ROWS = const [
    const['USA', 950,  500,  200],
    const['Japan',150,  990,  200],
  ];

  ChartData data = new ChartData(COLUMNS, ROWS);
  ChartConfig config;
  ChartArea area;
  Element host = new DivElement()..classes.add('host');

  // Helper for constructing the SvgArcData of each slice of the pie.
  List<SvgArcData> produceArcData(List rows) {
    var arcDataList = [];
    var layout = new PieLayout();
    var innerRadius = 0;
    // height is shorter than width.
    var pieRadius = area.layout.renderArea.height / 2;
    var outerRadius = pieRadius - 10;
    var sliceRadius = (pieRadius - 10 - innerRadius) / rows.length;

    for (var i = 0; i < rows.length; i++) {
      var arcData = layout.layout(rows[i]);
      arcData.forEach((e) {
        e.innerRadius = outerRadius - sliceRadius * (i + 1) + 0.5;
        e.outerRadius = outerRadius - sliceRadius * i;
      });

      arcDataList.addAll(arcData);
    }

    return arcDataList;
  }

  // Extracts the data used to compute each pie in the input.
  List extractPieData() {
    return new List()..addAll(area.data.rows.map((e) {
      var row = [];
      for (var measure in config.series.elementAt(0).measures) {
        row.add(e[measure]);
      }
      return row;
    }));
  }

  void checkRenderResult() {
    // Check dimension of the chart element.
    var chartElement = host.querySelector('.charted-chart');
    expect(chartElement.attributes['width'], CHART_WIDTH.toString());
    expect(chartElement.attributes['height'], CHART_HEIGHT.toString());

    // Should have as much slicesList and statsList text as there are measures.
    var rowGroups = host.querySelectorAll('.row-group');
    var slicesList = [];
    var statsList = [];
    for (var rowGroup in rowGroups) {
      slicesList.add(rowGroup.children.where((e) =>
          e.classes.contains('pie-path')));
      statsList.add(rowGroup.children.where((e) =>
          e.classes.contains('statistic')));
      expect(slicesList.last.length,
          area.config.series.elementAt(0).measures.length);
      expect(statsList.last.length,
          area.config.series.elementAt(0).measures.length);
  }

    // Check offset for the actual render area.
    var xOffset = area.layout.renderArea.width / 2;
    var yOffset = area.layout.renderArea.height / 2;
    expect(rowGroups.elementAt(0).attributes['transform'],
        'translate(${xOffset}, ${yOffset})');

    // Tests all the text elements that show the percentage stats of each slice.
    var pieRows = extractPieData();
    for (var i = 0; i < statsList.length; i++) {
      var pieData = pieRows.elementAt(i);
      var sum = pieData.reduce((a, b) => a + b);
      var textElements = statsList[i];
      for (var j = 0; j < textElements.length; j++) {
        var stat = textElements.elementAt(j);
        num percentage = pieData.elementAt(j) / sum;
        percentage.round();
        expect((percentage * 100).round().toString() + '%', stat.text);
      }
    }

    // Tests the path of each slices in each pie.  Utilizing the PieLayout and
    // SvgArc which is individually tested.
    var arc = new SvgArc();
    var arcDataList = produceArcData(pieRows);
    for (var i = 0; i < slicesList.length; i++) {
      var slices = slicesList[i];  // Slices of one pie.
      for (var j = 0; j < slices.length; j++) {
         expect(slices.elementAt(j).attributes['d'],
             arc.path(arcDataList[i * slices.length + j], 0, host));
      }
    }
  }

  test('pie chart renderer test', () {
    var chartAreaHost = new DivElement()..classes.add('chart-host'),
    series = new ChartSeries('pie', [1, 2, 3], new PieChartRenderer());
    host.children.add(chartAreaHost);
    config = new ChartConfig([series], [0]);
    config.minimumSize = new Rect.size(CHART_WIDTH, CHART_HEIGHT);
    area = new ChartArea(chartAreaHost, data, config, dimensionAxesCount: 0);
    area.draw();

    // The series group is not painted until the axis is painted.  However
    // The ChartArea.draw current doesn't return a Future upon paint completion
    // Also there is currently a default transition that we can not remove (will
    // change in the near future).  Set enough delay to ensure all the elements
    // in the chart has finished their initial animation.
    new Timer(new Duration(milliseconds:1000), expectAsync(checkRenderResult));
  });
}