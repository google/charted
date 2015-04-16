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
      ..attr('clip-path', 'url(#render-area-clippath)')
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

    var enter = bar.enter.append('path')
      ..each((d, i, e) {
        var measure = series.measures.elementAt(i),
            colorStylePair = colorForKey(measure:measure);

        e.classes.add('bar-rdr-bar ${colorStylePair.last}');
        e.attributes
          ..['d'] = buildPath(d, i, animateBarGroups)
          ..['stroke-width'] = '${theme.defaultStrokeWidth}px';

        e.style
          ..setProperty('fill', colorStylePair.first)
          ..setProperty('stroke', colorStylePair.first);

        if (!animateBarGroups) {
          e.attributes['data-column'] = '$measure';
        }
      })
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    if (animateBarGroups) {
      bar.each((d, i, e) {
        var measure = series.measures.elementAt(i),
            colorStylePair = colorForKey(measure: measure);
        e.attributes['data-column'] = '$measure';
        e.classes
          ..removeWhere((x) => ChartState.CLASS_NAMES.contains(x))
          ..add(colorStylePair.last);
        e.style
          ..setProperty('fill', colorStylePair.first)
          ..setProperty('stroke', colorStylePair.first);
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
  Selection getSelectionForColumn(int column) =>
      root.selectAll('.bar-rdr-bar[data-column="$column"]');

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(
        new _ChartEvent(scope.event, area,
            series, row, series.measures.elementAt(index), data));
  }
}
