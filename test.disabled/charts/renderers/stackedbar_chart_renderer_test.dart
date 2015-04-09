library charted.test.stackedbarchartrenderer;

import 'dart:async';
import 'dart:html';

import 'package:charted/charts/charts.dart';
import 'package:charted/core/core.dart';
import 'package:charted/scale/scale.dart';
import 'package:unittest/unittest.dart';

// TODO(midoringo): Add more complex tests on 0 height bars.
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

    // Create a new Linear scale for the y attribute.
    var yScale = new LinearScale();
    // 2190 is max sum of one row (stack) in ROWS, but it would get niced to
    // 2500.
    yScale.domain = [0, 2500];
    yScale.range = [area.layout.renderArea.height, 0];

    // Tests the width and height and offsets of each bar within the groups.
    for (var i = 0; i < seriesGroup.children.length; i++) {
      var group = seriesGroup.children[i];

      // Check the number of bars in a group is the same as the measures in the
      // seires.
      expect(group.children.length, measures.length);

      var bars = group.children;
      var y = area.layout.renderArea.height;
      for (var m = 0; m < measures.length; m++) {
        // The bars is drawn reversed so we can have first column of input on
        // top of the stack.
        var reversedIndex = measures.length - m - 1;
        expect(bars[m].attributes['width'], (xScale.rangeBand -
            area.theme.defaultStrokeWidth).toString());
        var height = (area.layout.renderArea.height -
            yScale.apply(ROWS[i][measures.elementAt(reversedIndex)])).round();
        var separatorOffset = area.theme.defaultSeparatorWidth +
            area.theme.defaultStrokeWidth;

        y -= height;
        expect(bars[m].attributes['y'], y.toString());

        // The first bar has -1 height so it doesn't draw on top of x-axis.
        if (m == 0) {
          height -= 1;
        } else {
          // The rest of the bar has offset on the border + separator between
          // the bars.
          height -= separatorOffset;
        }
        expect(bars[m].attributes['height'], height.toString());
      }
    }
  }

  test('stacked bar chart renderer test', () {
    var chartAreaHost = new DivElement()..classes.add('chart-host'),
    series = new ChartSeries('stacked-bar', [1, 2, 3],
        new StackedBarChartRenderer());
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