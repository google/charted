//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class BarChartRenderer extends CartesianRendererBase {
  static const RADIUS = 2;

  final Iterable<int> dimensionsUsingBand = const[0];
  final bool alwaysAnimate;

  @override
  final String name = "bar-rdr";

  BarChartRenderer({this.alwaysAnimate: false});

  /// Returns false if the number of dimension axes on the area is 0.
  /// Otherwise, the first dimension scale is used to render the chart.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area is CartesianArea;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var verticalBars = !area.config.isLeftAxisPrimary;

    var measuresCount = series.measures.length,
        measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    var rows = new List()
      ..addAll(area.data.rows.map((e) =>
          new List.generate(
              measuresCount, (i) => e[series.measures.elementAt(i)])));

    var dimensionVals = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var bars = new OrdinalScale()
      ..domain = new Range(series.measures.length).toList()
      ..rangeRoundBands([0, dimensionScale.rangeBand]);

    // Create and update the bar groups.

    var groups = root.selectAll('.bar-rdr-rowgroup').data(rows);
    var animateBarGroups = alwaysAnimate || !groups.isEmpty;

    groups.enter.append('g')
      ..classed('bar-rdr-rowgroup')
      ..attrWithCallback('transform', (d, i, c) => verticalBars ?
          'translate(${dimensionScale.scale(dimensionVals[i])}, 0)' :
          'translate(0, ${dimensionScale.scale(dimensionVals[i])})');
    groups.attrWithCallback('data-row', (d, i, e) => i);
    groups.exit.remove();

    if (animateBarGroups) {
      groups.transition()
        ..attrWithCallback('transform', (d, i, c) => verticalBars ?
            'translate(${dimensionScale.scale(dimensionVals[i])}, 0)' :
            'translate(0, ${dimensionScale.scale(dimensionVals[i])})')
        ..duration(theme.transitionDurationMilliseconds);
    }

    var barWidth = bars.rangeBand.abs() -
        theme.defaultSeparatorWidth - theme.defaultStrokeWidth;

    // Create and update the bars
    // Avoids animation on first render unless alwaysAnimate is set to true.

    var bar = groups.selectAll(
        '.bar-rdr-bar').dataWithCallback((d, i, c) => rows[i]);
    var getBarLength = (d) {
      var scaled = measureScale.scale(d).round() - 1,
          ht = verticalBars ? rect.height - scaled : scaled;
      return (ht < 0) ? 0 : ht;
    };
    var getBarPos = (d) {
      num scaled = measureScale.scale(d) - theme.defaultStrokeWidth;
      return scaled.round();
    };
    var buildPath = (d, int i, bool animate) {
      return verticalBars
          ? topRoundedRect(
              bars.scale(i).toInt() + theme.defaultStrokeWidth,
              animate ? rect.height : getBarPos(d),
              barWidth, animate ? 0 : getBarLength(d), RADIUS)
          : rightRoundedRect(
              1, bars.scale(i).toInt() + theme.defaultStrokeWidth,
              animate ? 0 : getBarLength(d), barWidth, RADIUS);
    };

    var enter = bar.enter.appendWithCallback((d, i, e) {
        var rect = Namespace.createChildElement('path', e),
            measure = series.measures.elementAt(i),
            row = int.parse(e.dataset['row']),
            color = colorForValue(measure, row),
            style = stylesForValue(measure, row);

        rect.classes.add('bar-rdr-bar ${style.join(" ")}');
        rect.attributes
          ..['d'] = buildPath(d, i, animateBarGroups)
          ..['stroke-width'] = '${theme.defaultStrokeWidth}px'
          ..['fill'] = color
          ..['stroke'] = color;

        if (!animateBarGroups) {
          rect.attributes['data-column'] = '$measure';
        }
        return rect;
      })
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    if (animateBarGroups) {
      bar.each((d, i, e) {
        var measure = series.measures.elementAt(i),
            row = int.parse(e.parent.dataset['row']),
            color = colorForValue(measure, row),
            styles = stylesForValue(measure, row);
        e.attributes
          ..['data-column'] = '$measure'
          ..['fill'] = color
          ..['stroke'] = color;
        e.classes
          ..removeAll(ChartState.VALUE_CLASS_NAMES)
          ..addAll(styles);
      });

      bar.transition()
        ..attrWithCallback('d', (d, i, e) => buildPath(d, i, false));
    }

    bar.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.bar-rdr-rowgroup').remove();
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

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
    var groups = host.querySelectorAll('.bar-rdr-rowgroup');
    if (groups == null || groups.isEmpty) return;

    for(int i = 0, len = groups.length; i < len; ++i) {
      var group = groups.elementAt(i),
          bars = group.querySelectorAll('.bar-rdr-bar'),
          row = int.parse(group.dataset['row']);

      for(int j = 0, barsCount = bars.length; j < barsCount; ++j) {
        var bar = bars.elementAt(j),
            column = int.parse(bar.dataset['column']),
            color = colorForValue(column, row);

        bar.classes.removeAll(ChartState.VALUE_CLASS_NAMES);
        bar.classes.addAll(stylesForValue(column, row));
        bar.attributes
          ..['fill'] = color
          ..['stroke'] = color;
      }
    }
  }

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(
        new _ChartEvent(scope.event, area,
            series, row, series.measures.elementAt(index), data));
  }
}
