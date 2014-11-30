/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class PieChartRenderer extends BaseRenderer {
  static const STATS_PERCENTAGE = 'percentage-only';
  static const STATS_VALUE = 'value-only';
  static const STATS_VALUE_PERCENTAGE = 'value-percentage';

  final Iterable<int> dimensionsUsingBand = const[];
  final statsMode;
  final num innerRadius;

  SelectionScope _scope;
  List<List> _prevRows = null;
  double _prevSlice;

  PieChartRenderer({this.innerRadius: 0, this.statsMode: STATS_PERCENTAGE});

  /*
   * Returns false if the number of dimension axes != 0. Pie chart can only
   * be rendered on areas with no axes.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area.dimensionAxesCount == 0;
  }

  @override
  void draw(GElement element) {
    _ensureReadyToDraw(element);

    var rows = new List()..addAll(area.data.rows.map((e) {
      var row = [];
      for (var measure in series.measures) {
        row.add(e[measure]);
      }
      return row;
    }));

    var radius = math.min(rect.width, rect.height) / 2;
    var outerRadius = radius - 10;
    var sliceRadius = (radius - 10 - innerRadius) / rows.length;

    if (_prevRows == null) {
      _prevRows = new List<List>();
      _prevSlice = sliceRadius;
    }

    while (_prevRows.length < rows.length)
      _prevRows.add(new List());
    while (_prevRows.length > rows.length)
      _prevRows.removeLast();
    for (int i = 0; i < _prevRows.length; i++) {
      while (_prevRows[i].length > rows[i].length)
        _prevRows[i].removeLast();
      while (_prevRows[i].length < rows[i].length)
        _prevRows[i].add(0);
    }

    var group = root.selectAll('.row-group').data(rows);
    group.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('data-row', (d, i, e) => i)
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${rect.width / 2}, ${rect.height / 2})');
    group.exit.remove();

    var layout = new PieLayout();
    var arc = new SvgArc();

    List<List> prevArcData = new List<List>();
    for (int i = 0; i < rows.length; i++) {
      prevArcData.add(layout.layout(_prevRows[i]));
      for (int j = 0; j < rows[i].length; j++) {
        prevArcData[i][j].innerRadius =
            outerRadius - _prevSlice * (i + 1);
        if (prevArcData[i][j].innerRadius < 0)
          prevArcData[i][j].innerRadius = 0;
        prevArcData[i][j].outerRadius = outerRadius - _prevSlice * i;
        if (prevArcData[i][j].outerRadius < prevArcData[i][j].innerRadius)
          prevArcData[i][j].outerRadius = prevArcData[i][j].innerRadius;
      }
    }

    List<List> arcData = new List<List>();
    for (int i = 0; i < rows.length; i++) {
      arcData.add(layout.layout(rows[i]));
      for (int j = 0; j < rows[i].length; j++) {
        arcData[i][j].innerRadius = outerRadius - sliceRadius * (i + 1) + 0.5;
        arcData[i][j].outerRadius = outerRadius - sliceRadius * i;
      }
    }

    var pie = group.selectAll('.pie-path')
        .dataWithCallback((d, i, c) => prevArcData[i]);
    pie.enter.append('path')
        ..classed('pie-path')
        ..attrWithCallback('fill', (d, i, e) => colorForKey(i))
        ..attrWithCallback('d', (d, i, e) {
          return arc.path(d, i, host);
        })
        ..attr('stroke-width', '1px')
        ..style('stroke', "#ffffff");

    pie.dataWithCallback((d, i, c) => arcData[i]);
    pie.transition()
      ..attrWithCallback('fill', (d, i, e) => colorForKey(i))
      ..attrTween('d', (d, i, e) {
          int o = ((outerRadius - d.outerRadius) / sliceRadius).round();
          return (t) => arc.path(interpolateSvgArcData(
            prevArcData[o][i], arcData[o][i])(t), i, host);
        })
      ..duration(theme.transitionDuration);
    pie
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));
    pie.exit.remove();

    for (int i = 0; i < rows.length; i++) {
      for (int j = 0; j < rows[i].length; j++)
        _prevRows[i][j] = rows[i][j];
    }

    _prevSlice = sliceRadius;

    List total = new List();
    rows.forEach((d) {
      var sum = 0;
      d.forEach((e) => sum += e);
      total.add(sum);
    });

    var ic = -1,
        order = 0;
    var statistic = group.selectAll('.statistic')
        .dataWithCallback((d, i, c) => arcData[i]);

    statistic.enter.append('text')
        ..classed('statistic')
        ..style('fill', 'white')
        ..attrWithCallback('transform', (d, i, c) {
          var offsets = arc.centroid(d, i, c);
          return 'translate(${offsets[0]}, ${offsets[1]})';
        })
        ..attr('dy', '.35em')
        ..style('text-anchor', 'middle');

    statistic
        ..textWithCallback((d, i, e) {
          if (i <= ic) order++;
          ic = i;
          return _processSliceText(d.data, total[order]);
        })
        ..attr('opacity', '0')
        ..style('pointer-events', 'none')
        ..attrWithCallback('transform', (d, i, c) {
          var offsets = arc.centroid(d, i, c);
          return 'translate(${offsets[0]}, ${offsets[1]})';
        });

    statistic.transition()
        ..attr('opacity', '1')
        ..delay(theme.transitionDuration)
        ..duration(theme.transitionDuration);

    statistic.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.row-group').remove();
  }

  String _processSliceText(value, total) {
    var significant = value * 100 / total >= 5;
    if (statsMode == STATS_PERCENTAGE) {
      return (significant) ? '${(value * 100 / total).toStringAsFixed(0)}%': '';
    } else if (statsMode == STATS_VALUE) {
      return (significant) ? value.toString() : '';
    } else {
      return (significant) ?
          '${value} (${(value * 100 / total).toStringAsFixed(0)}%)': '';
    }
  }

  @override
  double get bandInnerPadding => 0.0;

  @override
  double get bandOuterPadding => 0.0;

  @override
  Extent get extent => const Extent(0, 100);

  void _event(StreamController controller, data, int index, Element e) {
     if (controller == null) return;
     var rowStr = e.parent.dataset['row'];
     var row = rowStr != null ? int.parse(rowStr) : null;
     controller.add(
         new _ChartEvent(scope.event, area, series, row, index, data.value));
   }
}
