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

  ChartArea area;
  ChartSeries series;

  Element _host;
  Selection _group;
  SelectionScope _scope;

  StreamController<ChartEvent> _mouseOverController;
  StreamController<ChartEvent> _mouseOutController;
  StreamController<ChartEvent> _mouseClickController;

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  bool prepare(ChartArea area, ChartSeries series) {
    assert(area != null && series != null);
    if (area.dimensionAxesCount == 0) return false;
    this.area = area;
    this.series = series;
    return true;
  }

  void draw(Element element) {
    assert(area != null && series != null);
    assert(element != null && element is GElement);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var geometry = area.layout.renderArea,
        measuresCount = series.measures.length,
        measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first,
        theme = area.theme;

    String color(i) =>
        theme.getColorForKey(series.measures.elementAt(i));

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
    var svgLines = _group.selectAll('.line').data(initialValues);
    svgLines.enter.append('path')
        ..classed('line', true)
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color(i))
        ..on('mouseover', (d, i, e) {
          // Thickens the line on hover and show the points.
          _group.selectAll('.line-point-${i}')..style('opacity', '1');
          e.classes.add('active');
        })
        ..on('mouseout', (d, i, e) {
          // Thins the line on mouse out and hide the points.
          _group.selectAll('.line-point-${i}')..style('opacity', '0');
          e.classes.remove('active');
        })
        ..style('fill', 'none');

    int delay = 0;
    svgLines = _group.selectAll('.line').data(lines);
    svgLines.transition()
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color(i))
        ..duration(theme.transitionDuration)
        ..delayWithCallback((d, i, c) => delay += 50 ~/ series.measures.length);
    svgLines.exit.remove();

    // Draw the circle for each point in line for events.
    for (var columnIndex = 0; columnIndex < lines.length; columnIndex++) {
      _group.selectAll('.line-point-${columnIndex}').remove();
      var points = _group.selectAll('point').data(lines[columnIndex]);
      points.enter.append('circle')
        ..classed('line-point line-point-${columnIndex}', true)
        ..attr('r', 4)
        ..attrWithCallback('data-row', (d, i, e) => i)
        ..attrWithCallback('cx', (d, i, e) => _xAccessor(d, i))
        ..attrWithCallback('cy', (d, i, e) => _yAccessor(d, i))
        ..styleWithCallback('stroke', (d, i, e) => color(columnIndex))
        ..styleWithCallback('fill', (d, i, e) => color(columnIndex))
        ..style('opacity', '0')
        ..on('click', (d, i, e) => _event(_mouseClickController,
            d, columnIndex, e))
        ..on('mouseover', (d, i, e) {
          e.style.opacity = '1';
          _event(_mouseOverController, d, columnIndex, e);
        })
        ..on('mouseout', (d, i, e) {
          e.style.opacity = '0';
          _event(_mouseOutController, d, columnIndex, e);
        });
    }
  }

  void dispose() {
    if (_group == null) return;
    _group.selectAll('.line').remove();
  }

  double get bandInnerPadding => 1.0;
  double get bandOuterPadding =>
      area.theme.dimensionAxisTheme.axisOuterPadding;

  Extent get extent {
    assert(area != null && series != null);
    var rows = area.data.rows,
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

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(
        new _ChartEvent(_scope.event, area, series, row, index, data));
  }

  @override
  Stream<ChartEvent> get onValueMouseOver {
    if (_mouseOverController == null) {
      _mouseOverController = new StreamController.broadcast(sync: true);
    }
    return _mouseOverController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseOut {
    if (_mouseOutController == null) {
      _mouseOutController = new StreamController.broadcast(sync: true);
    }
    return _mouseOutController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseClick {
    if (_mouseClickController == null) {
      _mouseClickController = new StreamController.broadcast(sync: true);
    }
    return _mouseClickController.stream;
  }
}
