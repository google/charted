library charts;

import 'package:charted/charted.dart';

import 'dart:html';
import 'dart:math' as math;

// A constant representing the start time for generating fake time data.
var START_TIME_MS = new DateTime.now().millisecondsSinceEpoch;

// A constant offset for incrementally adding new time domain values.
const INCREMENT_MS = 1000 * 60 * 60 * 24;

const CHART_WIDTH = 600;
const CHART_HEIGHT = 400;

void main() {
  var RANDOM = new math.Random();

  // ------------
  // Charted test
  // ------------

  draw() {

    List getChartedColumns() {
      return [
        new ChartColumnSpec(label:'domain', type: ChartColumnSpec.TYPE_TIMESTAMP),
        new ChartColumnSpec(label:'m1'),
        new ChartColumnSpec(label:'m2'),
        new ChartColumnSpec(label:'m3'),
      ];
    }

    List getChartedData(int numPoints) {
      List data = [];
      for (var i = 0; i < numPoints; i++) {
        data.add([(START_TIME_MS + (INCREMENT_MS * i)),
          RANDOM.nextInt(4000),
          RANDOM.nextInt(4000),
          RANDOM.nextInt(4000)
        ]);
      }
      return data;
    }

    window.console.timeStamp("mew-script loaded");

    NumberInputElement input = document.getElementById('count');
    List COLUMNS = getChartedColumns();
    List DATA = getChartedData(int.parse(input.value));

    window.console.timeStamp("mew-data generated");

    Element chartedElement = document.querySelector('charted-test');

    ChartSeries series = new ChartSeries("Default series", [1],
        new LineChartRenderer());
    ChartData data = new ChartData(COLUMNS, DATA);
    ChartConfig config = new ChartConfig([series], [0])
        ..minimumSize = new Rect.size(CHART_WIDTH, CHART_HEIGHT);
    ChartArea base = new ChartArea(chartedElement, data, config,
        autoUpdate: true, dimensionAxesCount: 1);
    window.console.timeStamp("mew-prep done");
    base.draw();
    window.console.timeStamp("mew-draw done");
  }

  document.getElementById('start').onClick.listen((_) => draw());
}
