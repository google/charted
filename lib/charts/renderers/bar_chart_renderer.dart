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

  ChartArea chart;
  ChartSeries series;

  Element _host;
  Selection _group;
  SelectionScope _scope;

  void render(Element element) {
    assert(series != null);
    assert(chart != null);
    assert(element != null && element is GElement);

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
        measuresCount = series.measures.length,
        yScale = yAxis.scale,
        dimensionAxisId = ChartArea.DIMENSION_AXIS_IDS.first,
        xAxis = chart.getDimensionAxis(dimensionAxisId),
        xScale = xAxis.scale,
        theme = chart.theme;

    String color(i) =>
        theme.getColorForKey(series.measures.elementAt(i));

    var rows = new List()..addAll(chart.data.rows.map((e) {
      var row = [];
      for (var measure in series.measures) {
        row.add(e[measure]);
      }
      return row;
    }));

    var x = chart.data.rows.map(
        (row) => row.elementAt(chart.config.dimensions.first)).toList();

    var bars = new OrdinalScale()
        ..domain = new Range(series.measures.length).toList()
        ..rangeRoundBands([0, xScale.rangeBand]);

    var group = _group.selectAll('.row-group').data(rows);

    group.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${xScale.apply(x[i])}, 0)');
    group.exit.remove();

    group.transition()
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${xScale.apply(x[i])}, 0)')
        ..duration(theme.transitionDuration);

    int barWidth = bars.rangeBand - theme.separatorWidth - theme.strokeWidth;

    var bar = group.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);
    var enter = bar.enter.append('rect')
        ..classed('bar')
        ..attr('y', height)
        ..attr('height', 0)
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attrWithCallback('x', (d, i, c) => bars.apply(i) + theme.strokeWidth)
        ..attr('width', barWidth);

    bar.transition()
        ..attrWithCallback('x', (d, i, c) => bars.apply(i) + theme.strokeWidth)
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', barWidth)
        ..duration(theme.transitionDuration);

    int delay = 0;
    bar.transition()
        ..attrWithCallback('y', (d, i, c) => yScale.apply(d).round())
        ..attrWithCallback('height',
            (d, i, c) => height - yScale.apply(d).round())
        ..delayWithCallback((d, i, c) =>
            delay += theme.transitionDuration ~/
              (series.measures.length * rows.length));

    if (theme.strokeWidth > 0) {
      enter.attr('stroke-width', '${theme.strokeWidth}px');
      enter.styleWithCallback('stroke', (d, i, c) => color(i));
      bar.transition()
        ..styleWithCallback('stroke', (d, i, c) => color(i));
    }

    bar.exit.remove();
  }

  void clear() {
    if (_group == null) return;
    _group.selectAll('.row-group').remove();
  }

  double get bandInnerPadding {
    assert(series != null);
    assert(chart != null);

    var measuresCount = series.measures.length;
    return measuresCount > 2 ? 1 - (measuresCount / (measuresCount + 1)) :
        chart.theme.bandInnerPadding;
  }

  double get bandOuterPadding => chart.theme.bandOuterPadding;

  Extent get extent {
    assert(series != null);
    assert(chart != null);

    var rows = chart.data.rows,
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

  // We support drawing as long as we have atleast one dimension axes.
  bool isAreaCompatible(ChartArea area) => area.dimensionAxesCount >= 1;
}
