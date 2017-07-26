// Copyright 2017 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class StackedLineChartRenderer extends CartesianRendererBase {
  final Iterable<int> dimensionsUsingBand = const [];

  final bool alwaysAnimate;
  final bool showHoverCardOnTrackedDataPoints;
  final bool trackDataPoints;
  final bool trackOnDimensionAxis;
  final int quantitativeScaleProximity;

  bool _trackingPointsCreated = false;
  List _xPositions = [];

  // Currently hovered row/column
  int _savedOverRow = 0;
  int _savedOverColumn = 0;

  int currentDataIndex = -1;

  @override
  final String name = "stacked-line-rdr";

  StackedLineChartRenderer(
      {this.alwaysAnimate: false,
      this.showHoverCardOnTrackedDataPoints: false,
      this.trackDataPoints: true,
      this.trackOnDimensionAxis: false,
      this.quantitativeScaleProximity: 5});

  // Returns false if the number of dimension axes on the area is 0.
  // Otherwise, the first dimension scale is used to render the chart.
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    if (trackDataPoints) {
      _trackPointerInArea();
    }
    return area is CartesianArea;
  }

  @override
  void draw(Element element, {Future schedulePostRender}) {
    _ensureReadyToDraw(element);

    var measureScale = area.measureScales(series).first,
        dimensionScale = area.dimensionScales.first;

    // We only support one dimension axes, so we always use the
    // first dimension.
    var x = area.data.rows
        .map((row) => row.elementAt(area.config.dimensions.first))
        .toList();

    var accumulated = new List.filled(x.length, 0.0);

    var reversedMeasures = series.measures.toList().reversed.toList();
    // Create lists of values used for drawing.
    // First Half: previous values reversed (need for drawing)
    // Second Half: current accumulated values (need for drawing)
    var lines = reversedMeasures.map((column) {
      var row = area.data.rows.map((values) => values[column]).toList();
      return accumulated.reversed.toList()..addAll(
          new List.generate(x.length, (i) => accumulated[i] += row[i]));
    }).toList();

    var rangeBandOffset =
        dimensionScale is OrdinalScale ? dimensionScale.rangeBand / 2 : 0;

    // If tracking data points is enabled, cache location of points that
    // represent data.
    if (trackDataPoints) {
      _xPositions =
          x.map((val) => dimensionScale.scale(val) + rangeBandOffset).toList();
    }

    var fillLine = new SvgLine(
        xValueAccessor: (d, i) {
          // The first x.length values are the bottom part of the path that
          // should be drawn backword. The second part is the accumulated values
          // that should be drawn forward.
          var xval = i < x.length ? x[x.length - i - 1] : x[i - x.length];
          return dimensionScale.scale(xval) + rangeBandOffset;
        },
        yValueAccessor: (d, i) => measureScale.scale(d));
    var strokeLine = new SvgLine(
        xValueAccessor: (d, i) => dimensionScale.scale(x[i]) + rangeBandOffset,
        yValueAccessor: (d, i) => measureScale.scale(d));

    // Add lines and hook up hover and selection events.
    var svgLines = root.selectAll('.stacked-line-rdr-line').data(lines.reversed);
    svgLines.enter.append('g');

    svgLines.each((d, i, e) {
      var column = series.measures.elementAt(i),
          color = colorForColumn(column),
          filter = filterForColumn(column),
          styles = stylesForColumn(column),
          fill = new SvgElement.tag('path'),
          stroke = new SvgElement.tag('path'),
          fillData = d,
          // Second half contains the accumulated data for this measure
          strokeData = d.sublist(x.length, d.length);
      e.attributes
        ..['stroke'] = color
        ..['fill'] = color
        ..['class'] = styles.isEmpty
          ? 'stacked-line-rdr-line'
          : 'stacked-line-rdr-line ${styles.join(' ')}'
        ..['data-column'] = '$column';
      fill.attributes
        ..['d'] = fillLine.path(fillData, i, e)
        ..['stroke'] = 'none';
      stroke.attributes
        ..['d'] = strokeLine.path(strokeData, i, e)
        ..['fill'] = 'none';
      e.children = [fill, stroke];
      if (isNullOrEmpty(filter)) {
        e.attributes.remove('filter');
      } else {
        e.attributes['filter'] = filter;
      }
    });

    if (area.state != null) {
      svgLines
        ..on('click', (d, i, e) => _mouseClickHandler(d, i, e))
        ..on('mouseover', (d, i, e) => _mouseOverHandler(d, i, e))
        ..on('mouseout', (d, i, e) => _mouseOutHandler(d, i, e));
    }

    svgLines.exit.remove();
  }

  @override
  void dispose() {
    _disposer.dispose();
    if (root == null) return;
    root.selectAll('.stacked-line-rdr-line').remove();
    root.selectAll('.stacked-line-rdr-point').remove();
  }

  @override
  Extent get extent {
    assert(area != null && series != null);
    var rows = area.data.rows,
        max = SMALL_INT_MIN,
        min = SMALL_INT_MAX,
        rowIndex = 0;

    rows.forEach((row) {
      var line = null;
      series.measures.forEach((idx) {
        var value = row.elementAt(idx);
        if (value != null && value.isFinite) {
          if (line == null) line = 0.0;
          line += value;
        }
      });
      if (line > max) max = line;
      if (line < min) min = line;
      rowIndex++;
    });

    return new Extent(min, max);
  }

  @override
  void handleStateChanges(List<ChangeRecord> changes) {
    var lines = host.querySelectorAll('.stacked-line-rdr-line');
    if (lines == null || lines.isEmpty) return;

    for (int i = 0, len = lines.length; i < len; ++i) {
      var line = lines.elementAt(i),
          column = int.parse(line.dataset['column']),
          filter = filterForColumn(column);
      line.classes.removeAll(ChartState.COLUMN_CLASS_NAMES);
      line.classes.addAll(stylesForColumn(column));
      line.attributes['stroke'] = colorForColumn(column);
      line.attributes['fill'] = colorForColumn(column);

      if (isNullOrEmpty(filter)) {
        line.attributes.remove('filter');
      } else {
        line.attributes['filter'] = filter;
      }
    }
  }

  void _createTrackingCircles() {
    var linePoints = root.selectAll('.stacked-line-rdr-point')
        .data(series.measures.toList().reversed);
    linePoints.enter.append('circle').each((d, i, e) {
      e.classes.add('stacked-line-rdr-point');
      e.attributes['r'] = '4';
    });

    linePoints
      ..each((d, i, e) {
        var color = colorForColumn(d);
        e.attributes
          ..['r'] = '4'
          ..['stroke'] = color
          ..['fill'] = color
          ..['data-column'] = '$d';
      })
      ..on('click', _mouseClickHandler)
      ..on('mousemove', _mouseOverHandler) // Ensure that we update values
      ..on('mouseover', _mouseOverHandler)
      ..on('mouseout', _mouseOutHandler);

    linePoints.exit.remove();
    _trackingPointsCreated = true;
  }

  void _showTrackingCircles(ChartEvent event, int row) {
    if (_trackingPointsCreated == false) {
      _createTrackingCircles();
    }

    double cumulated =  0.0;
    var yScale = area.measureScales(series).first;
    root.selectAll('.stacked-line-rdr-point').each((d, i, e) {
      var x = _xPositions[row],
          measureVal = cumulated += area.data.rows.elementAt(row).elementAt(d);
      if (measureVal != null && measureVal.isFinite) {
        var color = colorForColumn(d), filter = filterForColumn(d);
        e.attributes
          ..['cx'] = '$x'
          ..['cy'] = '${yScale.scale(measureVal)}'
          ..['fill'] = color
          ..['stroke'] = color
          ..['data-row'] = '$row';
        e.style
          ..setProperty('opacity', '1')
          ..setProperty('visibility', 'visible');
        if (isNullOrEmpty(filter)) {
          e.attributes.remove('filter');
        } else {
          e.attributes['filter'] = filter;
        }
      } else {
        e.style
          ..setProperty('opacity', '$EPSILON')
          ..setProperty('visibility', 'hidden');
      }
    });

    if (showHoverCardOnTrackedDataPoints) {
      var firstMeasureColumn = series.measures.first;
      mouseOverController.add(new DefaultChartEventImpl(
          event.source, area, series, row, firstMeasureColumn, 0));
      _savedOverRow = row;
      _savedOverColumn = firstMeasureColumn;
    }
  }

  void _hideTrackingCircles(ChartEvent event) {
    root.selectAll('.stacked-line-rdr-point')
      ..style('opacity', '0.0')
      ..style('visibility', 'hidden');
    if (showHoverCardOnTrackedDataPoints) {
      mouseOutController.add(new DefaultChartEventImpl(
          event.source, area, series, _savedOverRow, _savedOverColumn, 0));
    }
  }

  int _getNearestRowIndex(num x) {
    double lastSmallerValue = 0.0;
    var chartX = x - area.layout.renderArea.x;
    for (var i = 0; i < _xPositions.length; i++) {
      var pos = _xPositions[i];
      if (pos < chartX) {
        lastSmallerValue = pos;
      } else {
        return i == 0
            ? 0
            : (chartX - lastSmallerValue <= pos - chartX) ? i - 1 : i;
      }
    }
    return _xPositions.length - 1;
  }

  void _trackPointerInArea() {
    _trackingPointsCreated = false;
    _disposer.add(area.onMouseMove.listen((ChartEvent event) {
      if (area.layout.renderArea.contains(event.chartX, event.chartY)) {
        var row = _getNearestRowIndex(event.chartX);
        window.animationFrame.then((_) {
          _showTrackingCircles(event, row);
        });
      } else {
        _hideTrackingCircles(event);
      }
    }));
    _disposer.add(area.onMouseOut.listen((ChartEvent event) {
      _hideTrackingCircles(event);
    }));
  }

  void _mouseClickHandler(d, int i, Element e) {
    if (area.state != null) {
      var selectedColumn = int.parse(e.dataset['column']);
      area.state.isSelected(selectedColumn)
          ? area.state.unselect(selectedColumn)
          : area.state.select(selectedColumn);
    }
    if (mouseClickController != null && e.tagName == 'circle') {
      var row = int.parse(e.dataset['row']),
          column = int.parse(e.dataset['column']);
      mouseClickController.add(
          new DefaultChartEventImpl(scope.event, area, series, row, column, d));
    }
  }

  void _mouseOverHandler(d, int i, Element e) {
    if (area.state != null) {
      area.state.preview = int.parse(e.dataset['column']);
    }
    if (mouseOverController != null && e.tagName == 'circle') {
      _savedOverRow = int.parse(e.dataset['row']);
      _savedOverColumn = int.parse(e.dataset['column']);
      mouseOverController.add(new DefaultChartEventImpl(
          scope.event, area, series, _savedOverRow, _savedOverColumn, d));
    }
  }

  void _mouseOutHandler(d, int i, Element e) {
    if (area.state != null &&
        area.state.preview == int.parse(e.dataset['column'])) {
      area.state.preview = null;
    }
    if (mouseOutController != null && e.tagName == 'circle') {
      mouseOutController.add(new DefaultChartEventImpl(
          scope.event, area, series, _savedOverRow, _savedOverColumn, d));
    }
  }
}
