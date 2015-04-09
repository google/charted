library charted.test.barchartrenderer;

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
    const['USA', 9.50,  50,  2000],
    const['Japan',1.50,  99,  2000],
    const['Taiwan', 3.50,  127,  1337],
    const['France', 2.50,  29,  6000],
    const['Germany', 10.99,  999,  10000],
    const['England', 2.50,  10,  3000],
    const['Brazil', 1.50,  27,  6000],
    const['Argentina', 5.50,  37,  2000],
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

    // Should have as much bar groups as there are rows in data.
    var seriesGroup = host.querySelector('.series-group');
    expect(seriesGroup.children.length, area.data.rows.length);

    // Check offset for the actual render area.
    var xOffset = area.layout.renderArea.x;
    var yOffset = area.layout.renderArea.y;
    expect(seriesGroup.attributes['transform'],
        'translate(${xOffset},${yOffset})');

    // Test offsets of bar groups by dimension range band and the band
    // padding.
    var xScale = new OrdinalScale();
    xScale.domain = ROWS.map((e) => e[0]).toList();
    xScale.rangeRoundBands([0, area.layout.renderArea.width],
        area.theme.dimensionAxisTheme.axisBandInnerPadding,
        area.theme.dimensionAxisTheme.axisBandOuterPadding);
    for (var i = 0; i < seriesGroup.children.length; i++) {
      expect(seriesGroup.children[i].attributes['transform'],
          'translate(${xScale.range[i]}, 0)');
    }

    // The measures in the ChartSeries.
    var measures = area.config.series.elementAt(0).measures;
    var bar = new OrdinalScale()
        ..domain = measures
        ..rangeRoundBands([0, area.dimensionScales.first.rangeBand]);
    var barWidth = bar.rangeBand - area.theme.defaultSeparatorWidth -
        area.theme.defaultStrokeWidth;

    // Create a new Linear scale for the y attribute.
    var yScale = new LinearScale();
    yScale.domain = [0, 10000]; // 10000 is max value of the input data.
    yScale.range = [area.layout.renderArea.height, 0];

    // Tests the width and height and offsets of each bar within the groups.
    for (var i = 0; i < seriesGroup.children.length; i++) {
      var group = seriesGroup.children[i];

      // Check the number of bars in a group is the same as the measures in the
      // seires.
      expect(group.children.length, measures.length);

      // Offsets of bars within the group and the width of the bars are the
      // same base on the theme and the number of measures and available
      // space in the render area.
      var bars = group.children;
      for (var m = 0; m < measures.length; m++) {
        expect(bars[m].attributes['x'], ((1 + m) *
            (area.theme.defaultSeparatorWidth + area.theme.defaultStrokeWidth) +
            (m * barWidth)).toDouble().toString());
        expect(bars[m].attributes['width'], barWidth.toString());
        expect(bars[m].attributes['y'],
            (yScale.apply(ROWS[i][measures.elementAt(m)])).round().toString());
      }
    }
  }

  test('bar chart renderer test', () {
    var chartAreaHost = new DivElement()..classes.add('chart-host'),
    bar_series = new ChartSeries('bar', [2, 3], new BarChartRenderer());
    host.children.add(chartAreaHost);
    config = new ChartConfig([bar_series], [0]);
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