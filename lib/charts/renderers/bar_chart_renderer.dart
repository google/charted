/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/*
 * TODO(prsd): Move the common functionality into a base class
 * that we could inherit from.
 */

class BarChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[0];

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
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    assert(area != null && series != null);
    if (area.dimensionAxesCount == 0) return false;
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
        measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first,
        theme = area.theme;

    String color(i) =>
        theme.getColorForKey(series.measures.elementAt(i));

    var rows = new List()..addAll(area.data.rows.map((e) {
      var row = [];
      for (var measure in series.measures) {
        row.add(e[measure]);
      }
      return row;
    }));

    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var bars = new OrdinalScale()
        ..domain = new Range(series.measures.length).toList()
        ..rangeRoundBands([0, dimensionScale.rangeBand]);

    var group = _group.selectAll('.row-group').data(rows);

    group.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.apply(x[i])}, 0)');
    group.exit.remove();

    // TODO(psunkari): Try not to set an attribute with row index on the gorup.
    group.transition()
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.apply(x[i])}, 0)')
        ..attrWithCallback('data-row', (d, i, e) => i)
        ..duration(theme.transitionDuration);

    int barWidth = bars.rangeBand -
        theme.defaultSeparatorWidth - theme.defaultStrokeWidth;

    var bar = group.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);
    var enter = bar.enter.append('rect')
        ..classed('bar')
        ..attr('y', geometry.height)
        ..attr('height', 0)
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attrWithCallback(
            'x', (d, i, e) => bars.apply(i) + theme.defaultStrokeWidth)
        ..attr('width', barWidth)
        ..on('click', (d, i, e) => _event(_mouseClickController, d, i, e))
        ..on('mouseover', (d, i, e) => _event(_mouseOverController, d, i, e))
        ..on('mouseout', (d, i, e) => _event(_mouseOutController, d, i, e));

    bar.transition()
        ..attrWithCallback(
            'x', (d, i, c) => bars.apply(i) + theme.defaultStrokeWidth)
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', barWidth)
        ..duration(theme.transitionDuration);

    int delay = 0;
    bar.transition()
        ..attrWithCallback('y', (d, i, c) => measureScale.apply(d).round())
        // height -1 so bar does not overlap x axis.
        ..attrWithCallback('height',
            (d, i, c) => geometry.height - measureScale.apply(d).round() - 1)
        ..delayWithCallback((d, i, c) =>
            delay += theme.transitionDuration ~/
              (series.measures.length * rows.length));

    if (theme.defaultStrokeWidth > 0) {
      enter.attr('stroke-width', '${theme.defaultStrokeWidth}px');
      enter.styleWithCallback('stroke', (d, i, c) => color(i));
      bar.transition()
        ..styleWithCallback('stroke', (d, i, c) => color(i));
    }

    bar.exit.remove();
  }

  @override
  void dispose() {
    if (_group == null) return;
    _group.selectAll('.row-group').remove();
  }

  @override
  double get bandInnerPadding {
    assert(series != null && area != null);
    var measuresCount = series.measures.length;
    return measuresCount > 2 ? 1 - (measuresCount / (measuresCount + 1)) :
        area.theme.dimensionAxisTheme.axisBandInnerPadding;
  }

  @override
  double get bandOuterPadding {
    assert(series != null && area != null);
    return area.theme.dimensionAxisTheme.axisBandOuterPadding;
  }

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
