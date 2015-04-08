//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class PieChartRenderer extends LayoutRendererBase {
  static const STATS_PERCENTAGE = 'percentage-only';
  static const STATS_VALUE = 'value-only';
  static const STATS_VALUE_PERCENTAGE = 'value-percentage';

  final Iterable<int> dimensionsUsingBand = const[];
  final statsMode;
  final num innerRadiusRatio;
  final int maxSliceCount;

  PieChartRenderer({this.innerRadiusRatio: 0,
    this.statsMode: STATS_PERCENTAGE, this.maxSliceCount: SMALL_INT_MAX});

  /// Returns false if the number of dimension axes != 0. Pie chart can only
  /// be rendered on areas with no axes.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area is LayoutArea;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var radius = math.min(rect.width, rect.height) / 2,
        groupElement = element.querySelector('layout'),
        group;

    if (groupElement == null) {
      groupElement = Namespace.createChildElement('g', element);
      groupElement.classes.add('layout');
      groupElement.attributes['transform'] =
          'translate(${rect.width / 2}, ${rect.height / 2})';
      element.append(groupElement);
      group = scope.selectElements([groupElement]);
    }

    var measure = series.measures.first,
        dimension = area.config.dimensions.first,
        rows = area.data.rows.toList();

    rows.sort((a, b) => area.config.isRTL
        ? a[measure].compareTo(b[measure])
        : b[measure].compareTo(a[measure]));

    var data = (new PieLayout()..accessor = (d, i) => d[measure]).layout(rows),
        arc = new SvgArc(
            innerRadiusCallback: (d, i, e) => innerRadiusRatio * radius,
            outerRadiusCallback: (d, i, e) => radius);

    var colorKey = (int i) => area.config.isRTL
        ? theme.getColorForKey(rows.length - i - 1)
        : theme.getColorForKey(i);

    var pie = group.selectAll('.pie-path').data(data);
    pie.enter.append('path')
        ..classed('pie-path')
        ..attrWithCallback('fill', (d, i, e) => colorKey(i))
        ..attrWithCallback('d', (d, i, e) => arc.path(d, i, host))
        ..attr('stroke-width', '1px')
        ..style('stroke', "#ffffff");

    pie
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    pie.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.row-group').remove();
  }

  void _event(StreamController controller, data, int index, Element e) {
     if (controller == null) return;
     var rowStr = e.parent.dataset['row'];
     var row = rowStr != null ? int.parse(rowStr) : null;
     controller.add(
         new _ChartEvent(scope.event, area, series, row, index, data.value));
   }
}
