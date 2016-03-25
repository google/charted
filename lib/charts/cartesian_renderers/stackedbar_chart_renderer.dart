//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class StackedBarChartRenderer extends CartesianRendererBase {
  static const RADIUS = 2;

  final Iterable<int> dimensionsUsingBand = const [0];
  final bool alwaysAnimate;

  @override
  final String name = "stack-rdr";

  /// Used to capture the last measure with data in a data row.  This is used
  /// to decided whether to round the cornor of the bar or not.
  List<int> _lastMeasureWithData = [];

  StackedBarChartRenderer({this.alwaysAnimate: false});

  /// Returns false if the number of dimension axes on the area is 0.
  /// Otherwise, the first dimension scale is used to render the chart.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    if (area is! CartesianArea) {
      throw new ArgumentError.value(area, 'area',
          "ChartArea for StackedBarChartRenderer must be a CartesianArea");
    }
    _ensureAreaAndSeries(area, series);
    return true;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);
    var verticalBars = !area.config.isLeftAxisPrimary;

    var measuresCount = series.measures.length,
        measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    var rows = new List()
      ..addAll(area.data.rows.map((e) => new List.generate(measuresCount,
          (i) => e.elementAt(series.measures.elementAt(_reverseIdx(i))))));

    var dimensionVals = area.data.rows
        .map((row) => row.elementAt(area.config.dimensions.first))
        .toList();

    var groups = root.selectAll('.stack-rdr-rowgroup').data(rows);
    var animateBarGroups = alwaysAnimate || !groups.isEmpty;
    groups.enter.append('g')
      ..classed('stack-rdr-rowgroup')
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

    var bar =
        groups.selectAll('.stack-rdr-bar').dataWithCallback((d, i, c) => d);

    var prevOffsetVal = new List();

    // Keep track of "y" values.
    // These are used to insert values in the middle of stack when necessary
    if (animateBarGroups) {
      bar.each((d, i, e) {
        var offset = e.dataset['offset'],
            offsetVal = offset != null ? int.parse(offset) : 0;
        if (i == 0) {
          prevOffsetVal.add(offsetVal);
        } else {
          prevOffsetVal[prevOffsetVal.length - 1] = offsetVal;
        }
      });
    }

    var barWidth =
        (dimensionScale as OrdinalScale).rangeBand - theme.defaultStrokeWidth;

    // Calculate height of each segment in the bar.
    // Uses prevAllZeroHeight and prevOffset to track previous segments
    var prevAllZeroHeight = true, prevOffset = 0;
    var getBarLength = (d, i) {
      if (!verticalBars) return measureScale.scale(d).round();
      var retval = rect.height - measureScale.scale(d).round();
      if (i != 0) {
        // If previous bars has 0 height, don't offset for spacing
        // If any of the previous bar has non 0 height, do the offset.
        retval -= prevAllZeroHeight
            ? 1
            : (theme.defaultSeparatorWidth + theme.defaultStrokeWidth);
        retval += prevOffset;
      } else {
        // When rendering next group of bars, reset prevZeroHeight.
        prevOffset = 0;
        prevAllZeroHeight = true;
        retval -= 1; // -1 so bar does not overlap x axis.
      }

      if (retval <= 0) {
        prevOffset = prevAllZeroHeight
            ? 0
            : theme.defaultSeparatorWidth + theme.defaultStrokeWidth + retval;
        retval = 0;
      }
      prevAllZeroHeight = (retval == 0) && prevAllZeroHeight;
      return retval;
    };

    // Initial "y" position of a bar that is being created.
    // Only used when animateBarGroups is set to true.
    var ic = 10000000, order = 0;
    var getInitialBarPos = (i) {
      var tempY;
      if (i <= ic && i > 0) {
        tempY = prevOffsetVal[order];
        order++;
      } else {
        tempY = verticalBars ? rect.height : 0;
      }
      ic = i;
      return tempY;
    };

    // Position of a bar in the stack. yPos is used to keep track of the
    // offset based on previous calls to getBarY
    var yPos = 0;
    var getBarPos = (d, i) {
      if (verticalBars) {
        if (i == 0) {
          yPos = measureScale.scale(0).round();
        }
        return yPos -= (rect.height - measureScale.scale(d).round());
      } else {
        if (i == 0) {
          // 1 to not overlap the axis line.
          yPos = 1;
        }
        var pos = yPos;
        yPos += measureScale.scale(d).round();
        // Check if after adding the height of the bar, if y has changed, if
        // changed, we offset for space between the bars.
        if (yPos != pos) {
          yPos += (theme.defaultSeparatorWidth + theme.defaultStrokeWidth);
        }
        return pos;
      }
    };

    var buildPath = (d, int i, Element e, bool animate, int roundIdx) {
      var position = animate ? getInitialBarPos(i) : getBarPos(d, i),
          length = animate ? 0 : getBarLength(d, i),
          radius =
          series.measures.elementAt(_reverseIdx(i)) == roundIdx ? RADIUS : 0,
          path = (length != 0)
              ? verticalBars
                  ? topRoundedRect(0, position, barWidth, length, radius)
                  : rightRoundedRect(position, 0, length, barWidth, radius)
              : '';
      e.attributes['data-offset'] =
          verticalBars ? position.toString() : (position + length).toString();
      return path;
    };

    var enter = bar.enter.appendWithCallback((d, i, e) {
      var rect = Namespace.createChildElement('path', e),
          measure = series.measures.elementAt(_reverseIdx(i)),
          row = int.parse(e.dataset['row']),
          color = colorForValue(measure, row),
          filter = filterForValue(measure, row),
          style = stylesForValue(measure, row),
          roundIndex = _lastMeasureWithData[row];

      if (!isNullOrEmpty(style)) {
        rect.classes.addAll(style);
      }
      rect.classes.add('stack-rdr-bar');

      rect.attributes
        ..['d'] =
            buildPath(d == null ? 0 : d, i, rect, animateBarGroups, roundIndex)
        ..['stroke-width'] = '${theme.defaultStrokeWidth}px'
        ..['fill'] = color
        ..['stroke'] = color;

      if (!isNullOrEmpty(filter)) {
        rect.attributes['filter'] = filter;
      }
      if (!animateBarGroups) {
        rect.attributes['data-column'] = '$measure';
      }
      return rect;
    });

    enter
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    if (animateBarGroups) {
      bar.each((d, i, e) {
        var measure = series.measures.elementAt(_reverseIdx(i)),
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
        ..attrWithCallback('d', (d, i, e) {
          var row = int.parse(e.parent.dataset['row']),
              roundIndex = _lastMeasureWithData[row];
          return buildPath(d == null ? 0 : d, i, e, false, roundIndex);
        });
    }

    bar.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.stack-rdr-rowgroup').remove();
  }

  @override
  double get bandInnerPadding =>
      area.theme.getDimensionAxisTheme().axisBandInnerPadding;

  @override
  Extent get extent {
    assert(area != null && series != null);
    var rows = area.data.rows,
        max = SMALL_INT_MIN,
        min = SMALL_INT_MAX,
        rowIndex = 0;
    _lastMeasureWithData = new List.generate(rows.length, (i) => -1);

    rows.forEach((row) {
      var bar = null;
      series.measures.forEach((idx) {
        var value = row.elementAt(idx);
        if (value != null && value.isFinite) {
          if (bar == null) bar = 0;
          bar += value;
          if (value.round() != 0 && _lastMeasureWithData[rowIndex] == -1) {
            _lastMeasureWithData[rowIndex] = idx;
          }
        }
      });
      if (bar > max) max = bar;
      if (bar < min) min = bar;
      rowIndex++;
    });

    return new Extent(min, max);
  }

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
    var groups = host.querySelectorAll('.stack-rdr-rowgroup');
    if (groups == null || groups.isEmpty) return;

    for (int i = 0, len = groups.length; i < len; ++i) {
      var group = groups.elementAt(i),
          bars = group.querySelectorAll('.stack-rdr-bar'),
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
        series.measures.elementAt(_reverseIdx(index)), data));
  }

  // Stacked bar chart renders items from bottom to top (first measure is at
  // the bottom of the stack). We use [_reversedIdx] instead of index to
  // match the color and order of what is displayed in the legend.
  int _reverseIdx(int index) => series.measures.length - 1 - index;
}
