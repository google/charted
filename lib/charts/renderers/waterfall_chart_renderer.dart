/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class WaterfallChartRenderer extends BaseRenderer {
  final Iterable<int> dimensionsUsingBand = const[0];

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    return area.dimensionAxesCount != 0 && area.data is WaterfallChartData;
  }

  @override
  void draw(Element element) {
    _ensureReadyToDraw(element);

    var measuresCount = series.measures.length,
    measureScale = area.measureScales(series).first,
    dimensionScale = area.dimensionScales.first;

    // We support only one dimension, so always use the first one.
    var x = area.data.rows.map(
            (row) => row.elementAt(area.config.dimensions.first)).toList();

    List<Iterable> rows = new List()
      ..addAll(area.data.rows.map((e) {
      var row = [];
      for (var i = measuresCount - 1; i >= 0; i--) {
        row.add(e[series.measures.elementAt(i)]);
      }
      return row;
    }));

    // Pre-compute shift value on y-axis for non-base rows
    var yShift = new List(),
        runningTotal = 0;
    for (int i = 0; i < rows.length; i++) {
      var row = rows[i];
      if (_isBaseRow(i)) {
        runningTotal = 0;
      }
      yShift.add(runningTotal);
      var bar = 0;
      row.forEach((value) => bar += value);
      runningTotal += bar;

      // Handle Nagative incremental values:
      if (row.elementAt(0) < 0) {
        assert(row.every((value) => value <= 0));
        for (int j = 0; j < row.length; j++) {
          row[j] = 0 - row[j];
        }
        yShift[yShift.length - 1] += bar;
      }
    }

    var group = root.selectAll('.row-group').data(rows);
    group.enter.append('g')
      ..classed('row-group')
      ..attrWithCallback('transform', (d, i, c) =>
          'translate(${dimensionScale.apply(x[i])},'
          '${measureScale.apply(yShift[i]).round() - rect.height})');
    group.exit.remove();

    group.transition()
      ..attrWithCallback('transform', (d, i, c) =>
          'translate(${dimensionScale.apply(x[i])},'
          '${measureScale.apply(yShift[i]).round() - rect.height})')
      ..duration(theme.transitionDuration)
      ..attrWithCallback('data-row', (d, i, e) => i);

    /* TODO(prsd): Handle cases where x and y axes are swapped */
    var bar = group.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);

    var ic = -1,
    order = 0,
    prevY = new List()..add(0);

    bar.each((d, i, e) {
      if (i > ic) {
        prevY[prevY.length - 1] = e.attributes['y'];
      } else {
        prevY.add(e.attributes['y']);
      }
      ic = i;
    });

    ic = 1e100;
    var enter = bar.enter.append('rect')
      ..classed('bar')
      ..styleWithCallback('fill', (d, i, c) => colorForKey(_reverseIdx(i)))
      ..attr('width', dimensionScale.rangeBand - theme.defaultStrokeWidth)
      ..attrWithCallback('y', (d, i, c) {
      var tempY;
      if (i <= ic && i > 0) {
        tempY = prevY[order];
        order++;
      } else {
        tempY = rect.height;
      }
      ic = i;
      return tempY;
    })
      ..attr('height', 0)
      ..on('click', (d, i, e) => _event(mouseClickController, d, i, e))
      ..on('mouseover', (d, i, e) => _event(mouseOverController, d, i, e))
      ..on('mouseout', (d, i, e) => _event(mouseOutController, d, i, e));

    bar.transition()
      ..styleWithCallback('fill', (d, i, c) => colorForKey(_reverseIdx(i)))
      ..attr('width', dimensionScale.rangeBand - theme.defaultStrokeWidth)
      ..duration(theme.transitionDuration);

    var y = 0,
    length = bar.length,
    // Keeps track of heights of previously graphed bars. If all bars before
    // current one have 0 height, the current bar doesn't need offset.
    prevAllZeroHeight = true,
    // Keeps track of the offset already exist in the previous bar, when the
    // computed bar height is less than (theme.defaultSeparatorWidth +
    // theme.defaultStrokeWidth), this height is already discounted, so the
    // next bar's offset in height can be this much less than normal.
    prevOffset = 0;

    bar.transition()
      ..attrWithCallback('y', (d, i, c) {
      if (i == 0) y = measureScale.apply(0).round();
      return (y -= (rect.height - measureScale.apply(d).round()));
    })
      ..attrWithCallback('height', (d, i, c) {
      var ht = rect.height - measureScale.apply(d).round();
      if (i != 0) {
        // If previous bars has 0 height, don't offset for spacing
        // If any of the previous bar has non 0 height, do the offset.
        ht -= prevAllZeroHeight ? 1 :
        (theme.defaultSeparatorWidth + theme.defaultStrokeWidth);
        ht += prevOffset;
      } else {
        // When rendering next group of bars, reset prevZeroHeight.
        prevOffset = 0;
        prevAllZeroHeight = true;
        ht -= 1;
        // -1 so bar does not overlap x axis.
      }
      if (ht <= 0) {
        prevOffset = prevAllZeroHeight ? 0 :
        (theme.defaultSeparatorWidth + theme.defaultStrokeWidth) + ht;
        ht = 0;
      }
      prevAllZeroHeight = (ht == 0) && prevAllZeroHeight;
      return ht;
    })
      ..duration(theme.transitionDuration)
      ..delay(50);

    if (theme.defaultStrokeWidth > 0) {
      enter.attr('stroke-width', '${theme.defaultStrokeWidth}px');
      enter.styleWithCallback('stroke', (d, i, c) =>
          colorForKey(_reverseIdx(i)));
      bar.transition()
        ..styleWithCallback('stroke', (d, i, c) => colorForKey(_reverseIdx(i)));
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
    min = max,
    runningTotal = 0;

    for (int i = 0; i < rows.length; i++) {
      var row = rows[i];
      if (_isBaseRow(i)) {
        runningTotal = 0;
      }
      series.measures.forEach((idx) {
        runningTotal += row[idx];
      });
      if (runningTotal > max) max = runningTotal;
      if (runningTotal < min) min = runningTotal;
    }
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

  bool _isBaseRow(int index) =>
      area.data is WaterfallChartData ?
          (area.data as WaterfallChartData).baseRows.contains(index) : false;
}
