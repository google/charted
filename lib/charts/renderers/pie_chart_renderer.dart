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

  ChartArea area;
  ChartSeries series;

  Extent _extent;
  Element _host;
  Selection _group;
  SelectionScope _scope;
  List<List> _prevRows = null;
  double _prevSlice;
  num innerRadius;

  StreamController<ChartEvent> _mouseOverController;
  StreamController<ChartEvent> _mouseOutController;
  StreamController<ChartEvent> _mouseClickController;

  PieChartRenderer([this.innerRadius = 0]);

  /*
   * Returns false if the number of dimension axes != 0. Pie chart can only
   * be rendered on areas with no axes.
   */
  bool prepare(ChartArea area, ChartSeries series) {
    assert(area != null && series != null);
    if (area.dimensionAxesCount != 0) return false;
    this.area = area;
    this.series = series;
    return true;
  }

  void draw(GElement element) {
    assert(area != null && series != null);
    assert(element != null && element is GElement);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var geometry = area.layout.renderArea,
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

    var radius = math.min(geometry.width, geometry.height) / 2;
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

    var group = _group.selectAll('.row-group').data(rows);
    group.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('data-row', (d, i, e) => i)
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${geometry.width / 2}, ${geometry.height / 2})');
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
        ..style('stroke', "#ffffff");

    pie.dataWithCallback((d, i, c) => arcData[i]);
    pie.transition()
      ..attrWithCallback('fill', (d, i, e) => color(i))
      ..attrTween('d', (d, i, e) {
          int o = ((outerRadius - d.outerRadius) / sliceRadius).round();
          return (t) => arc.path(interpolateSvgArcData(
            prevArcData[o][i], arcData[o][i])(t), i, _host);
        })
      ..duration(theme.transitionDuration);
    pie
      ..on('click', (d, i, e) => _event(_mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(_mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(_mouseOutController, d, i, e));
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

  void dispose() {
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
    assert(area != null && series != null);
    if (_extent == null) {
      _extent = new Extent(0, 100);
    }
    return _extent;
  }

  void _event(StreamController controller, data, int index, Element e) {
     if (controller == null) return;
     var rowStr = e.parent.dataset['row'];
     var row = rowStr != null ? int.parse(rowStr) : null;
     controller.add(
         new _ChartEvent(_scope.event, area, series, row, index, data.value));
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
