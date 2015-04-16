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
  final String statsMode;
  final num innerRadiusRatio;
  final int maxSliceCount;
  final String otherItemsLabel;
  final String otherItemsColor;
  final showLabels;

  @override
  final String name = "pie-rdr";

  final List<ChartLegendItem> _legend = [];

  PieChartRenderer({
      num innerRadiusRatio: 0,
      bool showLabels,
      this.statsMode: STATS_PERCENTAGE,
      this.maxSliceCount: SMALL_INT_MAX,
      this.otherItemsLabel: 'Other',
      this.otherItemsColor: '#EEEEEE'})
      : showLabels = showLabels == null ? innerRadiusRatio == 0 : showLabels,
        innerRadiusRatio = innerRadiusRatio;

  /// Returns false if the number of dimension axes != 0. Pie chart can only
  /// be rendered on areas with no axes.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area is LayoutArea;
  }

  @override
  Iterable<ChartLegendItem> layout(
      Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var radius = math.min(rect.width, rect.height) / 2;
    root.attr('transform', 'translate(${rect.width / 2}, ${rect.height / 2})');

    // Pick only items that are valid - non-null and don't have null value
    var measure = series.measures.first,
        dimension = area.config.dimensions.first,
        rows = area.data.rows.where(
            (x) => x != null && x[measure] != null).toList();

    rows.sort((a, b) => b[measure].compareTo(a[measure]));

    // Limit items to the passed maxSliceCount
    var otherRow;
    if (rows.length > maxSliceCount) {
      var displayed = rows.take(maxSliceCount).toList();
      var otherItemsValue = 0;
      for (int i = displayed.length; i < rows.length; ++i) {
        otherItemsValue += rows.elementAt(i)[measure];
      }
      otherRow = new List(rows.first.length)
        ..[dimension] = otherItemsLabel
        ..[measure] = otherItemsValue;
      rows = displayed..add(otherRow);
    } else {
      otherRow = null;
    }

    if (area.config.isRTL) {
      rows = rows.reversed.toList();
    }

    var data = (new PieLayout()..accessor = (d, i) => d[measure]).layout(rows),
        arc = new SvgArc(
            innerRadiusCallback: (d, i, e) => innerRadiusRatio * radius,
            outerRadiusCallback: (d, i, e) => radius);

    var pie = root.selectAll('.pie-path').data(data);
    var colorForData = (Iterable row) =>
        row.hashCode == otherRow.hashCode
            ? theme.getOtherColor()
            : theme.getColorForKey(row.elementAt(dimension));

    pie.enter.append('path').each((d, i, e) {
      e.classes.add('pie-path');
      e.attributes
        ..['fill'] = colorForData(d.data)
        ..['d'] = arc.path(d, i, host)
        ..['stroke-width'] = '1px'
        ..['stroke'] = '#ffffff';
      e.append(
          Namespace.createChildElement('text', e)
            ..classes.add('pie-label'));
    });

    pie
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    pie.exit.remove();

    _legend.clear();
    var items = new List.generate(data.length, (i) {
      SvgArcData d = data.elementAt(i);
      Iterable row = d.data;
      return new ChartLegendItem(color: colorForData(row),
          label: row.elementAt(dimension), series: [series],
          value: '${(((d.endAngle - d.startAngle) * 50) / math.PI).toStringAsFixed(2)}%');
    });
    return _legend..addAll(area.config.isRTL ? items.reversed : items);
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.pie-path').remove();
  }

  void _event(StreamController controller, data, int index, Element e) {
     if (controller == null) return;
     var rowStr = e.parent.dataset['row'];
     var row = rowStr != null ? int.parse(rowStr) : null;
     controller.add(
         new _ChartEvent(scope.event, area, series, row, index, data.value));
   }
}
