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

    var measuresCount = series.measures.length,
        measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    // Create initial values for transitiion
    var initialValues = series.measures.map((column) {
      return area.data.rows.map((values) => 0).toList();
    }).toList();

    // Create lists of values in measure columns.
    var lines = series.measures.map((column) {
      return area.data.rows.map((values) => values[column]).toList();
    }).toList();

    // We only support one dimension axes, so we always use the
    // first dimension.
    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var rangeBandOffset = dimensionScale.rangeBand / 2;
    var _xAccessor = (d, i) => dimensionScale.apply(x[i]) + rangeBandOffset;
    var _yAccessor = (d, i) => measureScale.apply(d);

    var line = new SvgLine();
    line.xAccessor = _xAccessor;
    line.yAccessor = _yAccessor;

    // Draw the lines.
    // TODO (midoringo): Right now the default stroke-width is 2px, which is
    // hard for user to hover over. Maybe add an larger, invisible capture area?
    var svgLines = root.selectAll('.line').data(initialValues);
    svgLines.enter.append('path')
        ..classed('line', true)
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => colorForKey(i))
        ..on('mouseover', (d, i, e) {
          // Thickens the line on hover and show the points.
          root.selectAll('.line-point-${i}')..style('opacity', '1');
          e.classes.add('active');
        })
        ..on('mouseout', (d, i, e) {
          // Thins the line on mouse out and hide the points.
          root.selectAll('.line-point-${i}')..style('opacity', '0');
          e.classes.remove('active');
        })
        ..style('fill', 'none');

    int delay = 0;
    svgLines = root.selectAll('.line').data(lines);
    svgLines.transition()
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => colorForKey(i))
        ..duration(theme.transitionDuration)
        ..delayWithCallback((d, i, c) => delay += 50 ~/ series.measures.length);
    svgLines.exit.remove();

    // Draw the circle for each point in line for events.
    for (var columnIndex = 0; columnIndex < lines.length; columnIndex++) {
      root.selectAll('.line-point-${columnIndex}').remove();
      var points = root.selectAll('point').data(lines[columnIndex]);
      points.enter.append('circle')
        ..classed('line-point line-point-${columnIndex}', true)
        ..attr('r', 4)
        ..attrWithCallback('data-row', (d, i, e) => i)
        ..attrWithCallback('cx', (d, i, e) => _xAccessor(d, i))
        ..attrWithCallback('cy', (d, i, e) => _yAccessor(d, i))
        ..styleWithCallback('stroke', (d, i, e) => colorForKey(columnIndex))
        ..styleWithCallback('fill', (d, i, e) => colorForKey(columnIndex))
        ..style('opacity', '0')
        ..on('click',
            (d, i, e) => _event(mouseClickController, d, columnIndex, e))
        ..on('mouseover', (d, i, e) {
          e.style.opacity = '1';
          _event(mouseOverController, d, columnIndex, e);
        })
        ..on('mouseout', (d, i, e) {
          e.style.opacity = '0';
          _event(mouseOutController, d, columnIndex, e);
        });
    }
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.line').remove();
  }

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(
        new _ChartEvent(scope.event, area, series, row, index, data));
  }
}
