/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.charts;

class StackedBarChartRenderer implements ChartRenderer {
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

    var rows = new List()..addAll(chart.data.rows.map((e) {
      var row = [];
      for (var i = series.measures.length - 1; i >= 0; i--) {
        row.add(e[series.measures.elementAt(i)]);
      }
      return row;
    }));

    String color(i) =>
        chart.theme.getColorForKey(
            series.measures.elementAt(series.measures.length - 1 - i));

    // We support only one dimension, so always use the first one.
    var x = chart.data.rows.map(
        (row) => row.elementAt(chart.config.dimensions.first)).toList();

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

    /* TODO(prsd): Handle cases where x and y axes are swapped */
    var bar = group.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);

    var ic = -1,
        order = 0,
        prevY = new List();

    prevY.add(0);
    bar.each((d, i, e) {
      if (i > ic) {
        prevY[prevY.length - 1] = e.attributes['y'];
      } else {
        prevY.add(e.attributes['y']);
      }
      ic = i;
    });

    ic = 1e100;
    var enter = bar.enter.append('rect')
        ..classed('bar')
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', xScale.rangeBand - theme.strokeWidth)
        ..attrWithCallback('y', (d, i, c) {
            var tempY;
            if (i <= ic && i > 0) {
              tempY = prevY[order];
              order++;
            } else {
              tempY = height;
            }
            ic = i;
            return tempY;
          })
        ..attr('height', 0);

    bar.transition()
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', xScale.rangeBand - theme.strokeWidth)
        ..duration(theme.transitionDuration);

    var y = 0,
        length = bar.length;
    bar.transition()
        ..attrWithCallback('y', (d, i, c) {
            if (i == 0) y = yScale.apply(0).round();
            return (y -= (height - yScale.apply(d).round()));
          })
        ..attrWithCallback('height', (d, i, c) {
            var ht = height - yScale.apply(d).round();
            if (i != 0) ht -= (theme.separatorWidth + theme.strokeWidth);
            if (ht < 0) ht = 0;
            return ht;
          })
        ..duration(theme.transitionDuration)
        ..delay(50);

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

  double get bandInnerPadding => chart.theme.bandInnerPadding;
  double get bandOuterPadding => chart.theme.bandOuterPadding;

  Extent get extent {
    assert(series != null);
    assert(chart != null);

    var rows = chart.data.rows,
        max = rows[0][series.measures.first],
        min = max;

    rows.forEach((row) {
      if (row[series.measures.first] < min)
        min = row[series.measures.first];

      var bar = 0;
      series.measures.forEach((idx) {
        bar += row[idx];
      });
      if (bar > max) max = bar;
    });

    return new Extent(min, max);
  }

  // We support drawing as long as we have atleast one dimension axes.
  bool isAreaCompatible(ChartArea area) => area.dimensionAxesCount >= 1;
}
