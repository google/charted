/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class LineChartRenderer extends CartesianRendererBase {
  final Iterable<int> dimensionsUsingBand = const[];
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();
  final bool alwaysAnimate;

  List _xPositions = [];
  Map<int, CircleElement> _measureCircleMap = {};
  int currentDataIndex = -1;

  @override
  final String name = "line-rdr";

  LineChartRenderer({this.alwaysAnimate: false});

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    _trackPointerInArea();
    return area is CartesianArea;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    // Create lists of values in measure columns.
    var lines = series.measures.map((column) {
      return area.data.rows.map((values) => values[column]).toList();
    }).toList();

    // We only support one dimension axes, so we always use the
    // first dimension.
    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var rangeBandOffset =
        dimensionScale is OrdinalScale ? dimensionScale.rangeBand / 2 : 0;

    _xPositions =
        x.map((val) => dimensionScale.scale(val) + rangeBandOffset).toList();

    // Add circles that track user's pointer movements.
    var linePoints = root.selectAll('.line-rdr-point').data(series.measures);
    linePoints.enter.append('circle').each((d, i, e) {
      e.classes.add('line-rdr-point');
      e.attributes['r'] = '4';
    });

    linePoints.each((d, i, e) {
      var color = colorForColumn(d);
      e.attributes
        ..['r'] = '4'
        ..['stroke'] = color
        ..['fill'] = color
        ..['data-column'] = '$d';
    });

    linePoints.exit.remove();

    var line = new SvgLine(
        xValueAccessor: (d, i) => dimensionScale.scale(x[i]) + rangeBandOffset,
        yValueAccessor: (d, i) => measureScale.scale(d));

    // Add lines and hook up hover and selection events.
    var svgLines = root.selectAll('.line-rdr-line').data(lines);
    svgLines.enter.append('path')
        ..each((d, i, e) {
          e.classes.add('line-rdr-line');
          e.attributes['fill'] = 'none';
        });

    svgLines.each((d, i, e) {
      var column = series.measures.elementAt(i),
          color = colorForColumn(column),
          styles = stylesForColumn(column);
      e.classes.addAll(styles);
      e.attributes
        ..['d'] = line.path(d, i, e)
        ..['stroke'] = color
        ..['data-column'] = '$column';
    });

    svgLines.exit.remove();
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.line-rdr-line').remove();
    root.selectAll('.line-rdr-point').remove();
    _disposer.dispose();
  }

  Selection _getSelectionForColumn(int column) =>
      root.selectAll('.line-rdr-line[data-column="$column"]');

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
    resetStylesCache();
    for (int i = 0; i < series.measures.length; ++i) {
      var column = series.measures.elementAt(i),
          selection = _getSelectionForColumn(column),
          color = colorForColumn(column),
          styles = stylesForColumn(column);
      selection.each((d,i,e) {
        e.classes
          ..removeAll(ChartState.COLUMN_CLASS_NAMES)
          ..addAll(styles);
      });
      selection.transition()
        ..style('stroke', color)
        ..duration(50);
    }
  }

  void _showTrackingCircles(int row) {
    var yScale = area.measureScales(series).first;
    root.selectAll('.line-rdr-point').each((d, i, e) {
      var x = _xPositions[row];
      var y = yScale.scale(area.data.rows.elementAt(row).elementAt(d));
      e.attributes
        ..['cx'] = '$x'
        ..['cy'] = '$y';
      e.style.setProperty('opacity', '1');
    });
  }

  void _hideTrackingCircles() {
    root.selectAll('.line-rdr-point').style('opacity', '0.0');
  }

  int _getNearestRowIndex(double x) {
    var lastSmallerValue = 0;
    var chartX = x - area.layout.renderArea.x;
    for (var i = 0; i < _xPositions.length; i++) {
      var pos = _xPositions[i];
      if (pos < chartX) {
        lastSmallerValue = pos;
      } else {
        return i == 0 ? 0 :
          (chartX - lastSmallerValue <= pos - chartX) ? i - 1 : i;
      }
    }
    return _xPositions.length - 1;
  }

  void _trackPointerInArea() {
    _disposer.add(area.onMouseMove.listen((ChartEvent event) {
      if (area.layout.renderArea.contains(event.chartX, event.chartY)) {
        var renderAreaX = event.chartX - area.layout.renderArea.x,
            row = _getNearestRowIndex(event.chartX);
        window.animationFrame.then((_) => _showTrackingCircles(row));
      } else {
        _hideTrackingCircles();
      }
    }));
    _disposer.add(area.onMouseOut.listen((ChartEvent event) {
      _hideTrackingCircles();
    }));
  }
}
