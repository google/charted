/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class LineChartRenderer extends BaseRenderer {
  final Iterable<int> dimensionsUsingBand = const[];

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area.dimensionAxesCount != 0;
  }

  @override
  void draw(Element element) {
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

    var rangeBandOffset = dimensionScale.rangeBand / 2;
    var _xAccessor = (d, i) => dimensionScale.scale(x[i]) + rangeBandOffset;
    var _yAccessor = (d, i) => measureScale.scale(d);

    var line = new SvgLine();
    line.xAccessor = _xAccessor;
    line.yAccessor = _yAccessor;

    var svgLines = root.selectAll('.line').data(lines);
    svgLines.enter.append('path')
        ..each((d, i, e) {
          e.classes.add('line');
          e.style.setProperty('fill', 'none');
        });

    svgLines.each((d, i, e) {
      e.attributes['d'] = line.path(d, i, e);
      e.style.setProperty('stroke', colorForKey(i));
    });

    svgLines.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.line').remove();
  }
}
