/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.charts;

class PieChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[];

  ChartArea chart;
  ChartSeries series;

  Extent _extent;
  Element _host;
  Selection _group;
  SelectionScope _scope;
  List<List> _prevRows = null;
  double _prevSlice;

  void render(GElement element) {
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
        theme = chart.theme;

    String color(i) => theme.getColorForKey(i);

    var rows = new List()..addAll(series.measures.map((e) {
      return new List()..addAll(chart.data.rows.map((d) => d[e]));
    }));

    var radius = math.min(width, height) / 2;
    var outerRadius = radius - 10;
    var sliceRadius = theme.innerRadius < 0 ?
        (radius - 10) / (rows.length + 1) :
        (radius - 10 - theme.innerRadius) / rows.length;

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

    var group = _group.selectAll('.row-group').data(rows);
    group.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${width / 2}, ${height / 2})');
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
        ..attrWithCallback('fill', (d, i, e) => color(i))
        ..attrWithCallback('d', (d, i, e) {
          return arc.path(d, i, _host);
        })
        ..attr('stroke-width', '1px')
        ..style('stroke', "#ffffff");;

    pie.dataWithCallback((d, i, c) => arcData[i]);
    pie.transition()
      ..attrWithCallback('fill', (d, i, e) => color(i))
      ..attrTween('d', (d, i, e) {
          int o = ((outerRadius - d.outerRadius) / sliceRadius).round();
          return (t) => arc.path(interpolateSvgArcData(
            prevArcData[o][i], arcData[o][i])(t), i, _host);
        })
      ..duration(theme.transitionDuration);
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

  void clear() {
    if (_group == null) return;
    _group.selectAll('.row-group').remove();
  }

  String _processSliceText(value, total) {
    return value * 100 / total >= 5 ?
        '${(value * 100 / total).toStringAsFixed(0)}%': '';
  }

  double get bandInnerPadding => 0.0;
  double get bandOuterPadding => 0.0;

  Extent get extent {
    assert(series != null);
    assert(chart != null);
    if (_extent == null) {
      _extent = new Extent(0, 100);
    }
    return _extent;
  }

  bool isAreaCompatible(ChartArea area) => area.dimensionAxesCount == 0;
}
