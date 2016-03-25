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

  final Iterable<int> dimensionsUsingBand = const [0];
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
      ..addAll(area.data.rows.map((e) => new List.generate(
          measuresCount, (i) => e[series.measures.elementAt(i)])));

    var dimensionVals = area.data.rows
        .map((row) => row.elementAt(area.config.dimensions.first))
        .toList();

    var bars = new OrdinalScale()
      ..domain = new Range(series.measures.length).toList()
      ..rangeRoundBands([0, (dimensionScale as OrdinalScale).rangeBand]);

    // Create and update the bar groups.

    var groups = root.selectAll('.bar-rdr-rowgroup').data(rows);
    var animateBarGroups = alwaysAnimate || !groups.isEmpty;

    groups.enter.append('g')
      ..classed('bar-rdr-rowgroup')
      ..attrWithCallback(
          'transform',
          (d, i, c) => verticalBars
              ? 'translate(${dimensionScale.scale(dimensionVals[i])}, 0)'
              : 'translate(0, ${dimensionScale.scale(dimensionVals[i])})');
    groups.attrWithCallback('data-row', (d, i, e) => i);
    groups.exit.remove();

    if (animateBarGroups) {
      groups.transition()
        ..attrWithCallback(
            'transform',
            (d, i, c) => verticalBars
                ? 'translate(${dimensionScale.scale(dimensionVals[i])}, 0)'
                : 'translate(0, ${dimensionScale.scale(dimensionVals[i])})')
        ..duration(theme.transitionDurationMilliseconds);
    }

    // TODO: Test interactions between stroke width and bar width.

    var barWidth = bars.rangeBand.abs() -
            theme.defaultSeparatorWidth -
            theme.defaultStrokeWidth,
        strokeWidth = theme.defaultStrokeWidth,
        strokeWidthOffset = strokeWidth ~/ 2;

    // Create and update the bars
    // Avoids animation on first render unless alwaysAnimate is set to true.

    var bar =
        groups.selectAll('.bar-rdr-bar').dataWithCallback((d, i, c) => rows[i]),
        scaled0 = measureScale.scale(0).round();

    var getBarLength = (d) {
      var scaledVal = measureScale.scale(d).round(),
          ht = verticalBars
              ? (d >= 0 ? scaled0 - scaledVal : scaledVal - scaled0)
              : (d >= 0 ? scaledVal - scaled0 : scaled0 - scaledVal);
      ht = ht - strokeWidth;

      // If bar would be scaled to 0 height but data is not 0, render bar
      // at 1 pixel so user can see and hover over to see the data.
      return (ht < 0) ? 1 : ht;
    };
    var getBarPos = (d) {
      var scaledVal = measureScale.scale(d).round();

      // If bar would be scaled to 0 height but data is not 0, reserve 1 pixel
      // height plus strokeWidthOffset to position the bar.
      if (scaledVal == scaled0) {
        return verticalBars
            ? d > 0
                ? scaled0 - 1 - strokeWidthOffset
                : scaled0 + strokeWidthOffset
            : d > 0
                ? scaled0 + strokeWidthOffset
                : scaled0 - 1 - strokeWidthOffset;
      }
      return verticalBars
          ? (d >= 0 ? scaledVal : scaled0) + strokeWidthOffset
          : (d >= 0 ? scaled0 : scaledVal) + strokeWidthOffset;
    };
    var buildPath = (d, int i, bool animate) {
      // If data is null or 0, an empty path for the bar is returned directly.
      if (d == null || d == 0) return '';
      if (verticalBars) {
        var fn = d > 0 ? topRoundedRect : bottomRoundedRect;
        return fn(
            bars.scale(i).toInt() + strokeWidthOffset,
            animate ? rect.height : getBarPos(d),
            barWidth,
            animate ? 0 : getBarLength(d),
            RADIUS);
      } else {
        var fn = d > 0 ? rightRoundedRect : leftRoundedRect;
        return fn(getBarPos(d), bars.scale(i).toInt() + strokeWidthOffset,
            animate ? 0 : getBarLength(d), barWidth, RADIUS);
      }
    };

    bar.enter.appendWithCallback((d, i, e) {
      var rect = Namespace.createChildElement('path', e),
          measure = series.measures.elementAt(i),
          row = int.parse(e.dataset['row']),
          color = colorForValue(measure, row),
          filter = filterForValue(measure, row),
          style = stylesForValue(measure, row);

      if (!isNullOrEmpty(style)) {
        rect.classes.addAll(style);
      }
      rect.classes.add('bar-rdr-bar');

      rect.attributes
        ..['d'] = buildPath(d, i, animateBarGroups)
        ..['stroke-width'] = '${strokeWidth}px'
        ..['fill'] = color
        ..['stroke'] = color;

      if (!isNullOrEmpty(filter)) {
        rect.attributes['filter'] = filter;
      }
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
            filter = filterForValue(measure, row),
            styles = stylesForValue(measure, row);
        e.attributes
          ..['data-column'] = '$measure'
          ..['fill'] = color
          ..['stroke'] = color;
        e.classes
          ..removeAll(ChartState.VALUE_CLASS_NAMES)
          ..addAll(styles);
        if (isNullOrEmpty(filter)) {
          e.attributes.remove('filter');
        } else {
          e.attributes['filter'] = filter;
        }
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
    return measuresCount > 2
        ? 1 - (measuresCount / (measuresCount + 1))
        : area.theme.getDimensionAxisTheme().axisBandInnerPadding;
  }

  @override
  double get bandOuterPadding {
    assert(series != null && area != null);
    return area.theme.getDimensionAxisTheme().axisBandOuterPadding;
  }

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
    var groups = host.querySelectorAll('.bar-rdr-rowgroup');
    if (groups == null || groups.isEmpty) return;

    for (int i = 0, len = groups.length; i < len; ++i) {
      var group = groups.elementAt(i),
          bars = group.querySelectorAll('.bar-rdr-bar'),
          row = int.parse(group.dataset['row']);

      for (int j = 0, barsCount = bars.length; j < barsCount; ++j) {
        var bar = bars.elementAt(j),
            column = int.parse(bar.dataset['column']),
            color = colorForValue(column, row),
            filter = filterForValue(column, row);

        bar.classes.removeAll(ChartState.VALUE_CLASS_NAMES);
        bar.classes.addAll(stylesForValue(column, row));
        bar.attributes
          ..['fill'] = color
          ..['stroke'] = color;
        if (isNullOrEmpty(filter)) {
          bar.attributes.remove('filter');
        } else {
          bar.attributes['filter'] = filter;
        }
      }
    }
  }

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(new DefaultChartEventImpl(scope.event, area, series, row,
        series.measures.elementAt(index), data));
  }
}
