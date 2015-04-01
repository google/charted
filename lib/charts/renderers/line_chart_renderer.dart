/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class LineChartRenderer extends BaseRenderer {
  final Iterable<int> dimensionsUsingBand = const[];
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  List _xPositions = [];
  Map<int, CircleElement> _measureCircleMap = {};
  int currentDataIndex = -1;

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  @override
  bool prepare(ChartArea area, ChartSeries series) {
    _ensureAreaAndSeries(area, series);
    _disposer.add(area.selectedMeasures.listChanges.listen(
        _handleSelectedMeasureChange));
    _disposer.add(area.hoveredMeasures.listChanges.listen(
        _handleHoveredMeasureChange));
    _disposer.add(area.onMouseMove.listen(_showDataPoint));
    _disposer.add(area.onMouseOut.listen(_hideDataPoint));
    return area.dimensionAxesCount != 0;
  }

  @override
  void draw(Element element) {
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
    var _xAccessor = (d, i) => dimensionScale.scale(x[i]) + rangeBandOffset;
    var _yAccessor = (d, i) => measureScale.scale(d);

    // Add the circle elements and compute the x positions for approximating
    // the user's cursor to the nearest data point.  One circle is constructed
    // for each measure in the series.
    for (var measure in series.measures) {

      // Create the CircleElements, don't need to show them yet.
      var circle = new CircleElement();
      circle.attributes
      ..['r'] = '4'
      ..['stroke'] = area.theme.getColorForKey(measure)
      ..['fill'] = area.theme.getColorForKey(measure)
      ..['class'] = 'line-point line-point-${measure}';
      host.append(circle);
      _measureCircleMap[measure] = circle;
    }

    // Record the x position of data for cursor approximation.
    var xValues = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();
    for (var value in xValues) {
      _xPositions.add(dimensionScale.scale(value) + rangeBandOffset);
    }

    var line = new SvgLine(xValueAccessor: _xAccessor,
        yValueAccessor: _yAccessor);

    // Add lines and hook up hover and selection events.
    var svgLines = root.selectAll('.line').data(lines);
    svgLines.enter.append('path')
        ..each((d, i, e) {
          e.classes.add('line');
          e.style.setProperty('fill', 'none');
          _disposer.add(e.onMouseOver.listen((_) =>
              area.hoveredMeasures.add(series.measures.elementAt(i))));
          _disposer.add(e.onMouseOut.listen((_) =>
              area.hoveredMeasures.remove(series.measures.elementAt(i))));
          _disposer.add(e.onClick.listen((_) {
            var measure = series.measures.elementAt(i);
            area.selectedMeasures.contains(measure) ?
                area.selectedMeasures.remove(measure) :
                area.selectedMeasures.add(measure);
          }));
        });

    svgLines.each((d, i, e) {
      e.attributes['d'] = line.path(d, i, e);
      e.style.setProperty('stroke', colorForKey(i));
    });

    svgLines.exit.remove();
  }

  /// Makes line thicker and darken color when user hovers a line.  This effect
  /// is reverted on mouse out unless the line is selected.
  void _handleHoveredMeasureChange(List<ListChangeRecord> changes) {
    root.selectAll('.line').each((d, i, e) {
      var measure = series.measures.elementAt(i);
      // If the measure is hovered, set active and set color to darker color.
      if (area.hoveredMeasures.contains(measure)) {
        e.classes.add('active');
        e.style.setProperty('stroke', colorForKey(i, ChartTheme.STATE_ACTIVE));
      } else {
        // If the measure is not hovered and no measure is selected, set all
        // lines back to normal color
        if (area.selectedMeasures.isEmpty) {
          e.style.setProperty('stroke', colorForKey(i,
              ChartTheme.STATE_NORMAL));
        } else {
          // Else set all non selected lines to disabled color
          area.selectedMeasures.contains(measure) ?
              e.style.setProperty('stroke', colorForKey(i,
                  ChartTheme.STATE_NORMAL)) :
              e.style.setProperty('stroke', colorForKey(i,
                  ChartTheme.STATE_DISABLED));
        }

        // If the measure is not selected and not hovered, remove active.
        if (!area.selectedMeasures.contains(measure)) {
          e.classes.remove('active');
        }
      }
    });
  }

  /// Toggles the line selection, change the line back to normal color but the
  /// thickness of the line stays (from hover) to indicate line selection.
  /// When at least one line is selected, none selected lines are set to the
  /// lighter color.
  void _handleSelectedMeasureChange(List<ListChangeRecord> changes) {
    root.selectAll('.line').each((d, i, e) {
      var measure = series.measures.elementAt(i);

      if (area.selectedMeasures.isEmpty) {
        e.style.setProperty('stroke', colorForKey(i, ChartTheme.STATE_NORMAL));
      } else {
        if (area.selectedMeasures.contains(measure)) {
          e.style.setProperty('stroke', colorForKey(i, ChartTheme.STATE_NORMAL));
        } else {
          e.style.setProperty('stroke', colorForKey(i,
              ChartTheme.STATE_DISABLED));
        }
      }
    });
  }

  bool _isRenderArea(ChartEvent e) =>
      area.layout.renderArea.contains(e.chartX, e.chartY);

  /// Returns the point on the line that is closest to the cursor.
  int _getActiveDataIndex(double x) {
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

  /// When user hovers within the render area, approximate the closest data
  /// point on the line and display the circle on the data point for selected or
  /// hovered lines.
  void _showDataPoint(ChartEvent e) {
    if (_isRenderArea(e)) {
      // Find the nearest x position where there is a correcsponding value
      // in the data.  If it's the same as previously active index, do nothing.
      var activeDataIndex = _getActiveDataIndex(e.chartX);
      if (currentDataIndex != activeDataIndex) {
        currentDataIndex = activeDataIndex;
        window.requestAnimationFrame((_) {

          // Find the currently selectedMeasures and hoveredMeasures, if none is
          // selected, show dot for all.
          var activeMeasures = [];
          activeMeasures.addAll(area.selectedMeasures);
          activeMeasures.addAll(area.hoveredMeasures);

          if (activeMeasures.isEmpty) {
            activeMeasures.addAll(_measureCircleMap.keys);
          }

          _measureCircleMap.values.forEach((e) => e.style.opacity = '0');

          for (var measure in activeMeasures) {
            if (!_measureCircleMap.keys.contains(measure)) continue;
            var row = area.data.rows.elementAt(activeDataIndex);
            var yAccessor = (d, i) => area.measureScales(series).first.scale(d);
            var circle = _measureCircleMap[measure];
            circle.attributes
                ..['stroke'] = area.theme.getColorForKey(measure,
                    area.hoveredMeasures.contains(measure) ?
                    ChartTheme.STATE_ACTIVE : ChartTheme.STATE_NORMAL)
                ..['fill'] = area.theme.getColorForKey(measure,
                    area.hoveredMeasures.contains(measure) ?
                    ChartTheme.STATE_ACTIVE : ChartTheme.STATE_NORMAL)
                ..['cx'] = '${_xPositions[activeDataIndex]}'
                ..['cy'] = '${yAccessor(row.elementAt(measure),
                    activeDataIndex)}';
            circle.style.opacity = '1';
            mouseOverController.add(new _ChartEvent(e.source, area, series,
                currentDataIndex, measure, row.elementAt(measure)));
          }
        });
      }
    } else {
      _hideDataPoint(e);
    }
  }

  /// Hides circle on data point on mouse out.
  void _hideDataPoint(ChartEvent e) {
    _measureCircleMap.values.forEach((e) => e.style.opacity = '0');
    currentDataIndex = -1;
    mouseOutController.add(new _ChartEvent(e.source, area));
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.line').remove();
    _disposer.dispose();
  }
}
