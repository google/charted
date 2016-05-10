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

  final Iterable<int> dimensionsUsingBand = const [];
  final String statsMode;
  final num innerRadiusRatio;
  final int maxSliceCount;
  final String otherItemsLabel;
  final String otherItemsColor;
  final showLabels;
  final sortDataByValue;

  @override
  final String name = "pie-rdr";

  final List<ChartLegendItem> _legend = [];

  Iterable otherRow;

  PieChartRenderer(
      {num innerRadiusRatio: 0,
      bool showLabels,
      this.sortDataByValue: true,
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
  Iterable<ChartLegendItem> layout(Element element,
      {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var radius = math.min(rect.width, rect.height) / 2;
    root.attr('transform', 'translate(${rect.width / 2}, ${rect.height / 2})');

    // Pick only items that are valid - non-null and don't have null value
    var measure = series.measures.first,
        dimension = area.config.dimensions.first,
        indices = new List.generate(area.data.rows.length, (i) => i);

    // Sort row indices by value.
    if (sortDataByValue) {
      indices.sort((int a, int b) {
        var aRow = area.data.rows.elementAt(a),
            bRow = area.data.rows.elementAt(b),
            aVal = (aRow == null || aRow.elementAt(measure) == null)
                ? 0
                : aRow.elementAt(measure),
            bVal = (bRow == null || bRow.elementAt(measure) == null)
                ? 0
                : bRow.elementAt(measure);
        return bVal.compareTo(aVal);
      });
    }

    // Limit items to the passed maxSliceCount
    if (indices.length > maxSliceCount) {
      var displayed = indices.take(maxSliceCount).toList();
      var otherItemsValue = 0;
      for (int i = displayed.length; i < indices.length; ++i) {
        var index = indices.elementAt(i), row = area.data.rows.elementAt(index);
        otherItemsValue += row == null || row.elementAt(measure) == null
            ? 0
            : row.elementAt(measure);
      }
      otherRow = new List(max([dimension, measure]) + 1)
        ..[dimension] = otherItemsLabel
        ..[measure] = otherItemsValue;
      indices = displayed..add(SMALL_INT_MAX);
    } else {
      otherRow = null;
    }

    if (area.config.isRTL) {
      indices = indices.reversed.toList();
    }

    num accessor(d, int i) {
      var row = d == SMALL_INT_MAX ? otherRow : area.data.rows.elementAt(d);
      return row == null || row.elementAt(measure) == null
          ? 0
          : row.elementAt(measure) as num;
    }
    var data = (new PieLayout()..accessor = accessor).layout(indices);
    var arc = new SvgArc(
        innerRadiusCallback: (d, i, e) => innerRadiusRatio * radius,
        outerRadiusCallback: (d, i, e) => radius);
    var pie = root.selectAll('.pie-path').data(data);

    pie.enter.appendWithCallback((d, i, e) {
      var pieSector = Namespace.createChildElement('path', e)
        ..classes.add('pie-path');
      var styles = stylesForData(d.data, i);
      if (!isNullOrEmpty(styles)) {
        pieSector.classes.addAll(styles);
      }
      pieSector.attributes
        ..['fill'] = colorForData(d.data, i)
        ..['d'] = arc.path(d, i, host)
        ..['stroke-width'] = '1px'
        ..['stroke'] = '#ffffff';

      pieSector.append(Namespace.createChildElement('text', pieSector)
        ..classes.add('pie-label'));
      return pieSector;
    })
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    pie.each((d, i, e) {
      var styles = stylesForData(d.data, i);
      e.classes.removeAll(ChartState.VALUE_CLASS_NAMES);
      if (!isNullOrEmpty(styles)) {
        e.classes.addAll(styles);
      }
      e.attributes
        ..['fill'] = colorForData(d.data, i)
        ..['d'] = arc.path(d, i, host)
        ..['stroke-width'] = '1px'
        ..['stroke'] = '#ffffff';
    });

    pie.exit.remove();

    _legend.clear();
    var items = new List<ChartLegendItem>.generate(data.length, (i) {
      SvgArcData d = data.elementAt(i);
      Iterable row =
          d.data == SMALL_INT_MAX ? otherRow : area.data.rows.elementAt(d.data);

      return new ChartLegendItem(
          index: d.data,
          color: colorForData(d.data, i),
          label: row.elementAt(dimension),
          series: [series],
          value:
              '${(((d.endAngle - d.startAngle) * 50) / math.PI).toStringAsFixed(2)}%');
    });
    return _legend..addAll(area.config.isRTL ? items.reversed : items);
  }

  String colorForData(int row, int index) =>
      colorForValue(row, isTail: row == SMALL_INT_MAX);

  Iterable<String> stylesForData(int row, int i) =>
      stylesForValue(row, isTail: row == SMALL_INT_MAX);

  @override
  handleStateChanges(List<ChangeRecord> changes) {
    root.selectAll('.pie-path').each((d, i, e) {
      var styles = stylesForData(d.data, i);
      e.classes.removeAll(ChartState.VALUE_CLASS_NAMES);
      if (!isNullOrEmpty(styles)) {
        e.classes.addAll(styles);
      }
      e.attributes['fill'] = colorForData(d.data, i);
    });
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.pie-path').remove();
  }

  void _event(StreamController controller, data, int index, Element e) {
    // Currently, events are not supported on "Other" pie
    if (controller == null || data.data == SMALL_INT_MAX) return;
    controller.add(new DefaultChartEventImpl(scope.event, area, series,
        data.data, series.measures.first, data.value));
  }
}
