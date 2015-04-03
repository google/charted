//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class StackedBarChartRenderer extends BaseRenderer {
  final Iterable<int> dimensionsUsingBand = const[0];
  final alwaysAnimate;

  StackedBarChartRenderer({this.alwaysAnimate: false});

  /// Returns false if the number of dimension axes on the area is 0.
  /// Otherwise, the first dimension scale is used to render the chart.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area is CartesianChartArea;
  }

  @override
  void draw(Element element,
      {bool preRender: false, Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var measuresCount = series.measures.length,
        measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    var rows = new List()
      ..addAll(area.data.rows.map((e) =>
          new List.generate(
              measuresCount, (i) => e[series.measures.elementAt(i)])));

    var dimensionVals = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var groups = root.selectAll('.row-group').data(rows);
    var animateBarGroups = alwaysAnimate || !groups.isEmpty;

    groups.enter.append('g')
      ..classed('row-group')
      ..attrWithCallback('transform', (d, i, c) =>
          'translate(${dimensionScale.scale(dimensionVals[i])}, 0)');
    groups.attrWithCallback('data-row', (d, i, e) => i);
    groups.exit.remove();

    if (animateBarGroups) {
      groups.transition()
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.scale(dimensionVals[i])}, 0)')
        ..duration(theme.transitionDurationMilliseconds);
    }

    var bar = groups.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);
    var ic = -1,
        order = 0,
        prevY = new List();

    // Keep track of "y" values.
    // These are used to insert values in the middle of stack when necessary
    if (animateBarGroups) {
      prevY.add(0);
      bar.each((d, i, e) {
        if (i > ic) {
          prevY[prevY.length - 1] = e.attributes['y'];
        } else {
          prevY.add(e.attributes['y']);
        }
        ic = i;
      });
      ic = 1000000000;
    }

    var barWidth = '${dimensionScale.rangeBand - theme.defaultStrokeWidth}';

    // Calculate height of each segment in the bar.
    // Uses prevAllZeroHeight and prevOffset to track previous segments
    var prevAllZeroHeight = true,
        prevOffset = 0;
    var getBarHeight = (d, i) {
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
      return retval.toString();
    };

    // Initial "y" position of a bar that is being created.
    // Only used when animateBarGroups is set to true.
    var getInitialBarY = (i) {
      var tempY;
      if (i <= ic && i > 0) {
        tempY = prevY[order];
        order++;
      } else {
        tempY = rect.height;
      }
      ic = i;
      return tempY.toString();
    };

    // Position of a bar in the stack. yPos is used to keep track of the
    // offset based on previous calls to getBarY
    var yPos = 0,
        getBarY = (d, i) {
      if (i == 0) {
        yPos = measureScale.scale(0).round();
      }
      return '${yPos -= (rect.height - measureScale.scale(d).round())}';
    };

    var enter = bar.enter.append('rect')
      ..each((d, i, e) {
          e.classes.add('bar');
          e.attributes
            ..['height'] = animateBarGroups ? '0' : getBarHeight(d, i)
            ..['width'] = barWidth
            ..['y'] = animateBarGroups ? getInitialBarY(i) : getBarY(d, i)
            ..['stroke-width'] = '${theme.defaultStrokeWidth}';
          e.style.setProperty('fill', colorForKey(i));
          e.style.setProperty('stroke', colorForKey(i));
        })
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    if (animateBarGroups) {
      bar.transition()
        ..styleWithCallback('fill', (d, i, c) => colorForKey(i))
        ..styleWithCallback('stroke', (d, i, c) => colorForKey(i))
        ..attr('width', barWidth)
        ..duration(theme.transitionDurationMilliseconds);

      bar.transition()
        ..attrWithCallback('y', (d, i, c) => getBarY(d, i))
        ..attrWithCallback('height', (d, i, c) => getBarHeight(d, i))
        ..duration(theme.transitionDurationMilliseconds)
        ..delay(50);
    }

    bar.exit.remove();
  }

  @override
  double get bandInnerPadding =>
      area.theme.dimensionAxisTheme.axisBandInnerPadding;

  @override
  Extent get extent {
    assert(area != null && series != null);
    var rows = area.data.rows,
    max = rows[0][series.measures.first],
    min = max;

    rows.forEach((row) {
      if (row[series.measures.first] < min)
        min = row[series.measures.first];

      var bar = 0;
      series.measures.forEach((idx) {
        bar += row[idx];
      });
      if (bar > max) max = bar;
    });

    return new Extent(min, max);
  }

  void _event(StreamController controller, data, int index, Element e) {
    if (controller == null) return;
    var rowStr = e.parent.dataset['row'];
    var row = rowStr != null ? int.parse(rowStr) : null;
    controller.add(new _ChartEvent(
        scope.event, area, series, row, _reverseIdx(index), data));
  }

  // Because waterfall bar chart render the measures in reverse order to match
  // the legend, we need to reverse the index for color and event.
  int _reverseIdx(int index) => series.measures.length - 1 - index;
}
