//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class BubbleChartRenderer extends CartesianRendererBase {
  final Iterable<int> dimensionsUsingBand = const [];
  final double maxBubbleRadius;
  final bool alwaysAnimate;

  Element _host;
  Selection _group;
  SelectionScope _scope;

  @override
  final String name = "bubble-rdr";

  BubbleChartRenderer({this.maxBubbleRadius: 20.0, this.alwaysAnimate: false});

  /// BubbleChart needs two dimension axes.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area is CartesianArea && area.useTwoDimensionAxes == true;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    assert(series != null && area != null);
    assert(element != null && element is GElement);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var geometry = area.layout.renderArea,
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
    group.enter.append('g')..classed('measure-group');
    group.each((d, i, e) {
      e.style.setProperty('fill', color(i));
      e.attributes['data-column'] = series.measures.elementAt(i).toString();
    });
    group.exit.remove();

    var measures =
        group.selectAll('.bubble').dataWithCallback((d, i, e) => columns[i]);

    measures.enter.append('circle')..classed('bubble');
    measures.each((d, i, e) {
      e.attributes
        ..['transform'] = 'translate('
            '${xDimensionScale.scale(xDimensionVals[i])},'
            '${yDimensionScale.scale(yDimensionVals[i])})'
        ..['r'] = '${bubbleRadiusScale.scale(d) * bubbleRadiusFactor}'
        ..['data-row'] = i.toString();
    });
    measures.exit.remove();
    handleStateChanges([]);
  }

  @override
  void dispose() {
    if (_group == null) return;
    _group.selectAll('.row-group').remove();
  }

  @override
  double get bandInnerPadding => 1.0;

  @override
  double get bandOuterPadding =>
      area.theme.getDimensionAxisTheme().axisOuterPadding;

  @override
  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
        max = rows.first[series.measures.first],
        min = max;

    rows.forEach((row) {
      series.measures.forEach((idx) {
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
    var groups = host.querySelectorAll('.bar-rdr-rowgroup');
    if (groups == null || groups.isEmpty) return;

    for (int i = 0, len = groups.length; i < len; ++i) {
      var group = groups.elementAt(i),
          bars = group.querySelectorAll('.bar-rdr-bar'),
          row = int.parse(group.dataset['row']);

      for (int j = 0, barsCount = bars.length; j < barsCount; ++j) {
        var bar = bars.elementAt(j),
            column = int.parse(bar.dataset['column']),
            color = colorForValue(column, row);

        bar.classes.removeAll(ChartState.VALUE_CLASS_NAMES);
        bar.classes.addAll(stylesForValue(column, row));
        bar.style..setProperty('fill', color)..setProperty('stroke', color);
      }
    }
  }

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(new DefaultChartEventImpl(
        _scope.event, area, series, row, index, data));
  }
}
