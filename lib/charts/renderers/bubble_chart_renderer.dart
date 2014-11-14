/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class BubbleChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[];

  ChartArea area;
  ChartSeries series;

  final double maxBubbleRadius;

  Element _host;
  Selection _group;
  SelectionScope _scope;

  StreamController<ChartEvent> _mouseOverController;
  StreamController<ChartEvent> _mouseOutController;
  StreamController<ChartEvent> _mouseClickController;

  BubbleChartRenderer([this.maxBubbleRadius = 20.0]);

  /*
   * BubbleChart needs two dimension axes.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    assert(area != null && series != null);
    if (area.dimensionAxesCount != 2) return false;
    this.area = area;
    this.series = series;
    return true;
  }

  @override
  void draw(Element element) {
    assert(series != null && area != null);
    assert(element != null && element is GElement);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var geometry = area.layout.renderArea,
        measuresCount = series.measures.length,
        bubbleRadiusScale = area.measureScales(series).first,
        xDimensionScale = area.dimensionScales.first,
        yDimensionScale = area.dimensionScales.last,
        theme = area.theme,
        bubbleRadiusFactor =
            maxBubbleRadius / min([geometry.width, geometry.height]);

    String color(i) => theme.getColorForKey(series.measures.elementAt(i));

    // Measure values used to set size of the bubble.
    var columns = [];
    for (int m in series.measures) {
      columns.add(new List.from(
          area.data.rows.map((Iterable row) => row.elementAt(m))));
    }

    // Dimension values used to position the bubble.
    var xDimensionIndex = area.config.dimensions.first,
        yDimensionIndex = area.config.dimensions.last,
        xDimensionVals = [],
        yDimensionVals = [];
    for (var row in area.data.rows) {
      xDimensionVals.add(row.elementAt(xDimensionIndex));
      yDimensionVals.add(row.elementAt(yDimensionIndex));
    }

    var group = _group.selectAll('.measure-group').data(columns);
    group.enter.append('g')
        ..classed('measure-group')
        ..styleWithCallback('fill', (d, i, e) => color(i));
    group.exit.remove();

    var measures = group.selectAll('.bubble').dataWithCallback(
        (d, i, e) => columns[i]);
    var enter = measures.enter.append('circle')
        ..classed('bubble')
        ..attrWithCallback('transform',
            (d, i, e) => 'translate('
                '${xDimensionScale.apply(xDimensionVals[i])},'
                '${yDimensionScale.apply(yDimensionVals[i])})')
        ..attrWithCallback('r',
            (d, i, e) => '${bubbleRadiusScale.apply(d) * bubbleRadiusFactor}');
    measures.exit.remove();
  }

  @override
  void dispose() {
    if (_group == null) return;
    _group.selectAll('.row-group').remove();
  }

  @override
  double get bandInnerPadding => 1.0;

  @override
  double get bandOuterPadding => area.theme.dimensionAxisTheme.axisOuterPadding;

  @override
  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
        max = rows[0][series.measures.first],
        min = max;

    rows.forEach((row) {
      series.measures.forEach((idx) {
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
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
