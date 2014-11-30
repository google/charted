/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class BarChartRenderer extends BaseRenderer {
  final Iterable<int> dimensionsUsingBand = const[0];

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

    var groups = root.selectAll('.row-group').data(rows);

    groups.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.apply(x[i])}, 0)');
    groups.exit.remove();

    // TODO(psunkari): Try not to set an attribute with row index on the gorup.
    groups.transition()
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.apply(x[i])}, 0)')
        ..attrWithCallback('data-row', (d, i, e) => i)
        ..duration(theme.transitionDuration);

    int barWidth = bars.rangeBand -
        theme.defaultSeparatorWidth - theme.defaultStrokeWidth;

    var bar = groups.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);
    var enter = bar.enter.append('rect')
        ..classed('bar')
        ..attr('y', rect.height)
        ..attr('height', 0)
        ..styleWithCallback('fill', (d, i, c) => colorForKey(i))
        ..attrWithCallback(
            'x', (d, i, e) => bars.apply(i) + theme.defaultStrokeWidth)
        ..attr('width', barWidth)
        ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
        ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
        ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    bar.transition()
        ..attrWithCallback(
            'x', (d, i, c) => bars.apply(i) + theme.defaultStrokeWidth)
        ..styleWithCallback('fill', (d, i, c) => colorForKey(i))
        ..attr('width', barWidth)
        ..duration(theme.transitionDuration);

    int delay = 0;
    bar.transition()
        ..attrWithCallback('y', (d, i, c) => measureScale.apply(d).round())
        // height -1 so bar does not overlap x axis.
        ..attrWithCallback('height', (d, i, c) {
            var height = rect.height - measureScale.apply(d).round() - 1;
            return (height < 0) ? 0 : height;
        })
        ..delayWithCallback((d, i, c) =>
            delay += theme.transitionDuration ~/
              (series.measures.length * rows.length));

    if (theme.defaultStrokeWidth > 0) {
      enter.attr('stroke-width', '${theme.defaultStrokeWidth}px');
      enter.styleWithCallback('stroke', (d, i, c) => colorForKey(i));
      bar.transition()
          ..styleWithCallback('stroke', (d, i, c) => colorForKey(i));
    }

    bar.exit.remove();
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

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(
        new _ChartEvent(scope.event, area, series, row, index, data));
  }
}
