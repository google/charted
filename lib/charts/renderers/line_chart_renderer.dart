/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.charts;

class LineChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[];

  ChartArea chart;
  ChartSeries series;

  Element _host;
  Selection _group;
  SelectionScope _scope;

  void render(Element element) {
    assert(series != null);
    assert(chart != null);
    assert(element != null && element is GElement);
    assert(_host == null || _host == element);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var width = int.parse(element.attributes['width']),
        height = int.parse(element.attributes['height']),
        measureAxisId = ((series.measureAxisIds == null) ?
            ChartArea.MEASURE_AXIS_IDS.first :
                series.measureAxisIds.first),
        yAxis = chart.getMeasureAxis(measureAxisId),
        yScale = yAxis.scale,
        dimensionAxisId = ChartArea.DIMENSION_AXIS_IDS.first,
        xAxis = chart.getDimensionAxis(dimensionAxisId),
        xScale = xAxis.scale,
        theme = chart.theme;

    String color(i) =>
        theme.getColorForKey(series.measures.elementAt(i));

    // Create initial values for transitiion
    var initialValues = series.measures.map((column) {
      return chart.data.rows.map((values) => 0).toList();
    }).toList();

    // Create lists of values in measure columns.
    var lines = series.measures.map((column) {
      return chart.data.rows.map((values) => values[column]).toList();
    }).toList();

    // We only support one dimension axes, so we always use the
    // first dimension.
    var x = chart.data.rows.map(
        (row) => row.elementAt(chart.config.dimensions.first)).toList();

    var rangeBandOffset =
        (xAxis.usingRangeBands == true ? xScale.rangeBand : 0) / 2;

    var line = new SvgLine();
    line.xAccessor = (d, i) => xScale.apply(x[i]) + rangeBandOffset;
    line.yAccessor = (d, i) => yScale.apply(d);

    var product = _group.selectAll(".line").data(initialValues);
    product.enter.append("path")
        ..classed("line", true)
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color(i))
        ..style('fill', 'none');

    int delay = 0;
    product = _group.selectAll(".line").data(lines);
    product.transition()
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color(i))
        ..duration(theme.transitionDuration)
        ..delayWithCallback((d, i, c) => delay += 50 ~/ series.measures.length);
    product.exit.remove();
  }

  void clear() {
    if (_group == null) return;
    _group.selectAll('.line').remove();
  }

  double get bandInnerPadding => 1.0;
  double get bandOuterPadding => chart.theme.outerPadding;

  Extent get extent {
    assert(series != null);
    assert(chart != null);

    var rows = chart.data.rows,
        max = rows[0][series.measures.first],
        min = max;

    rows.forEach((row) {
      series.measures.forEach((idx){
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }

  // We support drawing as long as we have atleast one dimension axes.
  bool isAreaCompatible(ChartArea area) => area.dimensionAxesCount >= 1;
}
