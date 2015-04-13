/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class LineChartRenderer extends CartesianRendererBase {
  final Iterable<int> dimensionsUsingBand = const[];
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  List _xPositions = [];
  Map<int, CircleElement> _measureCircleMap = {};
  int currentDataIndex = -1;

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area is CartesianArea;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    // Create lists of values in measure columns.
    var lines = series.measures.map((column) {
      return area.data.rows.map((values) => values[column]).toList();
    }).toList();

    // We only support one dimension axes, so we always use the
    // first dimension.
    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var rangeBandOffset =
        dimensionScale is OrdinalScale ? dimensionScale.rangeBand / 2 : 0;

    // Add the circle elements and compute the x positions for approximating
    // the user's cursor to the nearest data point.  One circle is constructed
    // for each measure in the series.
    for (var measure in series.measures) {
      var circle = new CircleElement();
      circle.attributes
        ..['r'] = '4'
        ..['stroke'] = area.theme.getColorForKey(measure)
        ..['fill'] = area.theme.getColorForKey(measure)
        ..['class'] = 'line-point line-point-${measure}';
      host.append(circle);
      _measureCircleMap[measure] = circle;
    }

    // Record the x position of data for cursor approximation.
    var xValues = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();
    for (var value in xValues) {
      _xPositions.add(dimensionScale.scale(value) + rangeBandOffset);
    }
    var line = new SvgLine(
        xValueAccessor: (d, i) => dimensionScale.scale(x[i]) + rangeBandOffset,
        yValueAccessor: (d, i) => measureScale.scale(d));

    // Add lines and hook up hover and selection events.
    var svgLines = root.selectAll('.line').data(lines);
    svgLines.enter.append('path')
        ..each((d, i, e) {
          e.classes.add('line');
          e.style.setProperty('fill', 'none');
        });

    svgLines.each((d, i, e) {
      e.attributes
        ..['d'] = line.path(d, i, e)
        ..['data-column'] = series.measures.elementAt(i).toString();
      e.style.setProperty('stroke', colorForKey(i));
    });

    svgLines.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.line').remove();
    _disposer.dispose();
  }

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
  }
}
