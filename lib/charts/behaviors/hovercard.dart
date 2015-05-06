//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

typedef Element HovercardBuilder(int column, int row);

///
/// Subscribe to events on the chart and display more information about the
/// visualization that is hovered or highlighted.
///
/// This behavior supports two event modes:
/// (1) State change: Subscribes to changes on ChartState
/// (2) Mouse tracking: Subscribe to onValueMouseOver and onValueMouseOut
///
/// Supports two placement modes for mouse-tracking:
/// (1) Place relative to mouse position
/// (2) Place relative to the visualized measure value.
///
/// Supports two modes for displayed content:
/// (1) Show all measure values at the current dimension value.
/// (2) Show the hovered value only
///
/// Optionally, takes a builder that is passed row, column values that
/// can be used to build custom tooltip
///
/// What makes the positioning logic complex?
/// (1) Is this a CartesianArea?
/// (2) Does the CartesianArea use two dimensions or just one?
/// (3) Does the CartesianArea use "bands" along the axes?
/// (4) How does measure correspond to positioning? Are the bars stacked?
///
/// So, how is the position computed?
/// (1) Uses ChartConfig to figure out which renderers are being used, asks
///     for extent of the row to roughly get the position along measure axis.
/// (2) Position along dimension axes is computed separately based on how
///     many dimensions are being used and if any of them use bands.
///
/// Constraints and known issues:
/// (0) The implementation isn't complete yet! Specifically for CartesianArea
///     that uses two axes.
/// (1) Even with all the logic, single value mode does not work well
///     with StackedBarChartRenderer
/// (2) Only mouse relative positioning is supported on LayoutArea
/// (3) Positioning only works for renderers that determine extent given a
///     single row.  Eg: Would not work with a water-fall chart.
///
class Hovercard implements ChartBehavior {
  final HovercardBuilder builder;

  bool _isMouseTracking;
  bool _isMouseRelativePlacement;
  bool _isMultiValue;
  bool _showDimensionTitle;

  Iterable placementOrder = const['top', 'right', 'bottom', 'left'];
  int offset = 20;

  ChartArea _area;
  ChartState _state;
  ChartEvent _currentEvent;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  Element _hovercardRoot;

  Hovercard({
      bool isMouseTracking,
      bool isMouseRelativePlacement,
      bool isMultiValue: false,
      bool showDimensionTitle: false,
      this.builder}) {
    _isMouseTracking = isMouseTracking;
    _isMouseRelativePlacement = isMouseRelativePlacement;
    _isMultiValue = isMultiValue;
    _showDimensionTitle = showDimensionTitle;
  }

  void init(ChartArea area, Selection _, Selection __) {
    _area = area;
    _state = area.state;

    // If we don't have state, fall back to mouse events.
    _isMouseTracking = _isMouseTracking == true || _state == null;

    // If placement was not specified, default to value relative placement.
    _isMouseRelativePlacement =
        _isMouseRelativePlacement == true || _area is! CartesianArea;

    // Subscribe to events.
    if (_isMouseTracking) {
      _disposer.addAll([
          _area.onValueMouseOver.listen(_handleMouseOver),
          _area.onValueMouseOut.listen(_handleMouseOut)
      ]);
    } else {
      _disposer.add(_state.changes.listen(_handleStateChange));
    }
  }

  void dispose() {
    _disposer.dispose();
    if (_hovercardRoot != null) _hovercardRoot.remove();
  }

  void _handleMouseOver(ChartEvent e) {
    _ensureHovercard();
  }

  void _handleMouseOut(ChartEvent e) {
    _ensureHovercard();
  }

  void _handleStateChange(Iterable<ChangeRecord> changes) {
    _ensureHovercard();

    var value = _state.hovered;
    if (_state.highlights.length == 1) {
      value = _state.highlights.first;
    }

    if (value == null) {
      _hovercardRoot.style
        ..visibility = 'hidden'
        ..opacity = '$EPSILON';
    } else {
      _hovercardRoot.children.clear();
      _hovercardRoot.append(_createTooltip(value.first, value.last));
      _hovercardRoot.style
        ..visibility = 'visible'
        ..opacity = '1.0';
      _updateTooltipPosition(column: value.first, row: value.last);
    }
  }

  void _ensureHovercard() {
    if (_hovercardRoot != null) return;
    _hovercardRoot = new Element.div();
    _hovercardRoot.classes.add('hovercard');
    if (_area.config.isRTL) {
      _hovercardRoot.attributes['dir'] = 'rtl';
      _hovercardRoot.classes.add('rtl');
    }
    _area.host.append(_hovercardRoot);
  }

  void _updateTooltipPosition({ChartEvent e, int column, int row}) {
    assert(e != null || column != null && row != null);
    if (e != null) {
      _positionAtMousePointer(e);
    } else {
      assert(_area is CartesianArea);
      if ((_area as CartesianArea).useTwoDimensionAxes) {
        _positionOnTwoDimensionCartesian(column, row);
      } else {
        _positionOnSingleDimensionCartesian(column, row);
      }
    }
  }

  void _positionAtMousePointer(ChartEvent e) {
    // TODO: Implement positioning at mouse pointer.
  }

  void _positionOnTwoDimensionCartesian(int column, int row) {
    // TODO: Implement multi dimension positioning.
  }

  void _positionOnSingleDimensionCartesian(int column, int row) {
    CartesianArea area = _area;
    var dimensionCol = area.config.dimensions.first,
        dimensionScale = area.dimensionScales.first,
        measureScale = _getScaleForColumn(column),
        dimensionOffset = this.offset,
        measureOffset = 0,
        dimensionCenterOffset = 0;

    // If we are using bands on the one axis that is shown
    // update position and offset accordingly.
    if (area.dimensionsUsingBands.contains(dimensionCol)) {
      assert(dimensionScale is OrdinalScale);
      dimensionOffset = (dimensionScale as OrdinalScale).rangeBand / 2;
      dimensionCenterOffset = dimensionOffset;
    }

    var rowData = area.data.rows.elementAt(row),
        measurePosition = 0,
        isNegative = false,
        dimensionPosition = dimensionScale.scale(
            rowData.elementAt(dimensionCol)) + dimensionCenterOffset;

    if (_isMultiValue) {
      var max = SMALL_INT_MIN,
          min = SMALL_INT_MAX;
      area.config.series.forEach((ChartSeries series) {
        CartesianRenderer renderer = series.renderer;
        Extent extent = renderer.extentForRow(rowData);
        if (extent.min < min) min = extent.min;
        if (extent.max > max) max = extent.max;
        measurePosition = measureScale.scale(max);
        isNegative = max < 0;
      });
    }
    else {
      var value = rowData.elementAt(column);
      isNegative = value < 0;
      measurePosition = measureScale.scale(rowData.elementAt(column));
    }

    _positionAtPoint(dimensionPosition, measurePosition,
        0, dimensionOffset, isNegative, area.config.isLeftAxisPrimary);
  }

  void _positionAtPoint(
      num x, num y, num xBand, num yBand, bool negative, bool isLeftPrimary) {
    var rect = _hovercardRoot.getBoundingClientRect(),
        width = rect.width,
        height = rect.height,
        scaleToHostY =
            (_area.theme.padding != null ? _area.theme.padding.top : 0) +
            (_area.layout.renderArea.y),
        scaleToHostX =
            (_area.theme.padding != null ? _area.theme.padding.start: 0) +
            (_area.layout.renderArea.x);

    if (scaleToHostY == null || scaleToHostY < 0) scaleToHostY = 0;

    if (isLeftPrimary) {
      _hovercardRoot.style
        ..top = '${x - height / 2 + scaleToHostY}px'
        ..left = negative
            ? '${y - width + scaleToHostX}px'
            : '${y + scaleToHostX}px';
    } else {
      _hovercardRoot.style
        ..top = negative
            ? '${y + scaleToHostY}px'
            : '${y - height + scaleToHostY}px'
        ..left = '${x - width / 2 + scaleToHostX}px';
    }
  }

  Element _createTooltip(int column, int row) {
    var rows = _area.data.rows,
        columns = _area.data.columns,
        element = new Element.div();
    if (_showDimensionTitle) {
      var titleElement = new Element.div()
        ..className = 'hovercard-title'
        ..text = _getDimensionTitle(column, row);
      element.append(titleElement);
    }

    var measureVals =  _getMeasuresData(column, row);
    measureVals.forEach((ChartLegendItem item) {
      var labelElement = new Element.div()
            ..className = 'hovercard-measure-label'
            ..text = item.label,
          valueElement = new Element.div()
            ..style.color = item.color
            ..className = 'hovercard-measure-value'
            ..text = item.value,
          measureElement = new Element.div()
            ..append(labelElement)
            ..append(valueElement);

      measureElement.className = _isMultiValue
          ? 'hovercard-measure hovercard-multi'
          : 'hovercard-measure hovercard-single';
      element.append(measureElement);
    });

    return element;
  }

  Iterable<ChartLegendItem> _getMeasuresData(int column, int row) {
    var rowData = _area.data.rows.elementAt(row),
        columns =  _area.data.columns,
        measureVals = <ChartLegendItem>[];

    if (_isMultiValue) {
      var displayedCols = [];
      _area.config.series.forEach((ChartSeries series) {
        series.measures.forEach((int column) {
          if (!displayedCols.contains(column)) displayedCols.add(column);
        });
      });
      displayedCols.sort();
      displayedCols.forEach((int column) {
        var spec = columns.elementAt(column),
            colorKey = _area.useRowColoring ? row : column,
            formatter = _getFormatterForColumn(column);
        measureVals.add(
            new ChartLegendItem(
                label: spec.label,
                value: formatter(rowData.elementAt(column)),
                color: _area.theme.getColorForKey(colorKey)));
      });
    } else {
      var spec = columns.elementAt(column),
          colorKey = _area.useRowColoring ? row : column,
          formatter = _getFormatterForColumn(column);
      measureVals.add(
          new ChartLegendItem(
              label: spec.label,
              value: formatter(rowData.elementAt(column)),
              color: _area.theme.getColorForKey(colorKey)));
    }

    return measureVals;
  }

  String _getDimensionTitle(int column, int row) {
    var rowData = _area.data.rows.elementAt(row),
        colSpec = _area.data.columns.elementAt(column);
    if (_area is CartesianArea) {
      var count = (_area as CartesianArea).useTwoDimensionAxes ? 2 : 1,
          dimensions = _area.config.dimensions.take(count);
      return dimensions.map(
          (int c) => _getFormatterForColumn(c)(rowData[c])).join(', ');
    } else {
      // TODO: Implement the LayoutArea case!
    }
  }

  // TODO: Move this to a common place?
  Scale _getScaleForColumn(int column) {
    var series = _area.config.series.firstWhere(
        (ChartSeries x) => x.measures.contains(column), orElse: () => null);
    return series != null
        ? (_area as CartesianArea).measureScales(series).first
        : null;
  }

  // TODO: Move this to a common place?
  FormatFunction _getFormatterForColumn(int column) {
    var formatter = _area.data.columns.elementAt(column).formatter;
    if (formatter == null && _area is CartesianArea) {
      var scale = _getScaleForColumn(column);
      if (scale != null) {
        formatter = scale.createTickFormatter();
      }
    }
    if (formatter == null) {
      formatter = identityFunction;
    }
    return formatter;
  }
}

