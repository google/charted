library charted.test.linechartrenderer;

import 'dart:async';
import 'dart:html';

import 'package:charted/charts/charts.dart';
import 'package:charted/core/core.dart';
import 'package:charted/scale/scale.dart';
import 'package:unittest/unittest.dart';

main() {
  const CHART_WIDTH = 1000;
  const CHART_HEIGHT = 400;

  List COLUMNS = [
    new ChartColumnSpec(label:'Country', type:ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label:'Stats1'),
    new ChartColumnSpec(label:'Stats2'),
    new ChartColumnSpec(label:'Stats3')
  ];

  const List ROWS = const [
    const['USA', 950,  500,  200],
    const['Japan',150,  990,  200],
    const['Taiwan', 350,  127,  1337],
    const['France', 250,  290,  600],
    const['Germany', 1100,  90,  1000],
    const['England', 250,  100,  300],
    const['Brazil', 150,  270,  600],
    const['Argentina', 550,  370,  200],
  ];

  ChartData data = new ChartData(COLUMNS, ROWS);
  ChartConfig config;
  ChartArea area;
  Element host = new DivElement()..classes.add('host');

  void checkRenderResult() {
    // Check dimension of the chart element.
    var chartElement = host.querySelector('.charted-chart');
    expect(chartElement.attributes['width'], CHART_WIDTH.toString());
    expect(chartElement.attributes['height'], CHART_HEIGHT.toString());

    // Should have as much lines as there is measures in the series.
    var seriesGroup = host.querySelector('.series-group');
    var lines = seriesGroup.children.where((e) => e.classes.contains('line'));
    expect(lines.length, area.config.series.elementAt(0).measures.length);

    // Check offset for the actual render area.
    var xOffset = area.layout.renderArea.x;
    var yOffset = area.layout.renderArea.y;
    expect(seriesGroup.attributes['transform'],
        'translate(${xOffset},${yOffset})');

    // Test offsets of bar groups by dimension range band and the band
    // padding.
    var xScale = new OrdinalScale();
    xScale.domain = ROWS.map((e) => e[0]).toList();
    xScale.rangeRoundBands([0, area.layout.renderArea.width], 1.0,
        area.theme.dimensionAxisTheme.axisOuterPadding);

    // Create a new Linear scale for the y attribute.
    var yScale = new LinearScale();

    // 1337 is max value in ROWS, but it would get niced to 1400.
    yScale.domain = [0, 1400];
    yScale.range = [area.layout.renderArea.height, 0];

    var xValues = xScale.domain;
    var xAccessor = (d, i) => xScale.apply(xValues[i]) + xScale.rangeBand / 2;
    var yAccessor = (d, i) => yScale.apply(d);
    var lineData = area.config.series.elementAt(0).measures.map((column) {
      return area.data.rows.map((values) => values[column]).toList();
    }).toList();

    // Tests the path of the svg lines created against the data.
    // The behavior for the circles on hover may change soon.  Currently too
    // many circle elements are being added and is a performance issue for large
    // data set.  Add test for that after the behavior change.
    var currentPoint;
    for (var i = 0; i < lines.length; i++) {
      var data = lineData[i];
      var path = lines.elementAt(i).attributes['d'];
      for (var j = 0; j < data.length; j++) {
        currentPoint = (j == 0 ? 'M' : 'L') +
            xAccessor(data[j], j).toString() + ',' +
            yAccessor(data[j], j).toString();
        expect(path.startsWith(currentPoint), isTrue);
        path = path.substring(currentPoint.length);
      }
    }
  }

  test('line chart renderer test', () {
    var chartAreaHost = new DivElement()..classes.add('chart-host'),
    series = new ChartSeries('line', [1, 2, 3],
        new LineChartRenderer());
    host.children.add(chartAreaHost);
    config = new ChartConfig([series], [0]);
    config.minimumSize = new Rect.size(CHART_WIDTH, CHART_HEIGHT);
    area = new ChartArea(chartAreaHost, data, config);
    area.draw();

    // The series group is not painted until the axis is painted.  However
    // The ChartArea.draw current doesn't return a Future upon paint completion
    // Also there is currently a default transition that we can not remove (will
    // change in the near future).  Set enough delay to ensure all the elements
    // in the chart has finished their initial animation.
    new Timer(new Duration(milliseconds:1000), expectAsync(checkRenderResult));
  });
}