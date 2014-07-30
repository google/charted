/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.charts;

class SparkChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[];

  ChartArea chart;
  ChartSeries series;

  Extent _extent;
  Element _host;
  Selection _group;
  SelectionScope _scope;

  void render(GElement element) {
    assert(series != null);
    assert(chart != null);
    assert(element != null);
    assert(_host == null || _host == element);
    // Spark charts support only one series
    // Any y values should be numeric
    assert(series.measures.length == 1);
    assert(chart.data.columns.elementAt(1).type == ChartColumnSpec.TYPE_NUMBER);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var width = int.parse(element.attributes['width']),
        height = int.parse(element.attributes['height']),
        theme = chart.theme;

    var x = chart.data.rows.map((row) => row.elementAt(0)).toList();
    var y = chart.data.rows.map((row) => row.elementAt(1)).toList();
    //  Create initial values for transition
    var initialValues = y.map((value) => 0).toList();

    String color = theme.getColorForKey(0);

    // Create scales based on width, height of host and the min max values
    // we are trying to show.
    var xScale = chart.data.columns.elementAt(0).createDefaultScale();
    if (xScale is OrdinalScale) {
      xScale.domain = x;
      xScale.rangePoints([0, width]);
    } else {
      xScale.domain = [min(x), max(x)];
      xScale.range = [0, width];
    }
    // We can assume LinearScale because we assert that y values are numeric.
    var yScale = new LinearScale()
        ..domain = [min(y), max(y)]
        ..range = [height, 0];
    var line = new SvgLine();
    line.xAccessor = (d, i) => (xScale.apply(x[i]));
    line.yAccessor = (d, i) => (yScale.apply(d));

    var product = _group.selectAll(".line").data([initialValues]);
    product.enter.append("path")
        ..classed("line", true)
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color)
        ..style('fill', 'none');

    int delay = 0;
    product = _group.selectAll(".line").data([y]);
    product.transition()
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color)
        ..duration(theme.transitionDuration)
        ..delayWithCallback((d, i, c) => delay += 50);
    product.exit.remove();
  }

  void clear() {
    if (_group == null) return;
    _group.selectAll('.line').remove();
  }

  double get bandInnerPadding => 0.0;
  double get bandOuterPadding => 0.0;

  Extent get extent {
    assert(series != null);
    assert(chart != null);
    if (_extent == null) {
      _extent = new Extent(0, 100);
    }
    return _extent;
  }

  bool isAreaCompatible(ChartArea area) => area.dimensionAxesCount == 0;
}
