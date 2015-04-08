//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class BarChartRenderer extends BaseRenderer {
  final Iterable<int> dimensionsUsingBand = const[0];
  final alwaysAnimate;

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

    var groups = root.selectAll('.row-group').data(rows);
    var animateBarGroups = alwaysAnimate || !groups.isEmpty;

    groups.enter.append('g')
      ..classed('row-group')
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

    var barWidth = (bars.rangeBand.abs() -
        theme.defaultSeparatorWidth - theme.defaultStrokeWidth).toString();

    // Create and update the bars
    // Avoids animation on first render unless alwaysAnimate is set to true.

    var bar = groups.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);
    var getBarHeight = (d) {
      var ht = (verticalBars ? rect.height : rect.width) -
          measureScale.scale(d).round() - 1;
      return (ht < 0) ? '0' : ht.toString();
    };
    var getBarY = (d) => measureScale.scale(d).round().toString();

    var enter = bar.enter.append('rect')
      ..each((d, i, e) {
        e.classes.add('bar');
        e.attributes
          ..[verticalBars ? 'x' : 'y'] =
              (bars.scale(i) + theme.defaultStrokeWidth).toString()
          ..[verticalBars ? 'y' : 'x'] = verticalBars ?
              (animateBarGroups ? rect.height.toString() : getBarY(d)) : '1'
          ..[verticalBars ? 'height' : 'width'] = animateBarGroups ? '0' :
              getBarHeight(d)
          ..[verticalBars ? 'width' : 'height'] = barWidth
          ..['stroke-width'] = '${theme.defaultStrokeWidth}px';
        if (!animateBarGroups) {
          e.style.setProperty('fill', colorForKey(i));
          e.style.setProperty('stroke', colorForKey(i));
        }
      })
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    if (animateBarGroups) {
      bar.transition()
        ..attrWithCallback(verticalBars ? 'x' : 'y', (d, i, c) =>
            bars.scale(i) + theme.defaultStrokeWidth)
        ..styleWithCallback('fill', (d, i, c) => colorForKey(i))
        ..styleWithCallback('stroke', (d, i, c) => colorForKey(i))
        ..attr(verticalBars ? 'width' : 'height', barWidth)
        ..duration(theme.transitionDurationMilliseconds);

      int delay = 0;
      bar.transition()
        ..attrWithCallback(verticalBars ? 'y' : 'x', (d, i, c) => getBarY(d))
        ..attrWithCallback(verticalBars ? 'height': 'width',
            (d, i, c) => getBarHeight(d))
        ..delayWithCallback((d, i, c) =>
            delay += theme.transitionDurationMilliseconds ~/
                (series.measures.length * rows.length));
    }

    bar.exit.remove();
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

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(
        new _ChartEvent(scope.event, area, series, row, index, data));
  }
}
