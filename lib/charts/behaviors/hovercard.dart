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
  static const _HOVERCARD_OFFSET = 20;
  final HovercardBuilder builder;

  bool _isMouseTracking;
  bool _isMultiValue;
  bool _showDimensionTitle;
  Iterable<int> _columnsToShow;

  Iterable placementOrder = const [
    'orientation',
    'top',
    'right',
    'bottom',
    'left',
    'orientation'
  ];

  ChartArea _area;
  ChartState _state;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  Element _hovercardRoot;

  Hovercard(
      {bool isMouseTracking,
      bool isMultiValue: false,
      bool showDimensionTitle: false,
      List<int> columnsToShow: const <int>[],
      this.builder}) {
    _isMouseTracking = isMouseTracking;
    _isMultiValue = isMultiValue;
    _showDimensionTitle = showDimensionTitle;
    _columnsToShow = columnsToShow;
  }

  void init(ChartArea area, Selection _, Selection __) {
    _area = area;
    _state = area.state;

    // If we don't have state, fall back to mouse events.
    _isMouseTracking =
        _isMouseTracking == true || _state == null || _area is LayoutArea;

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
    _hovercardRoot.children.clear();
    _hovercardRoot.append(builder != null
        ? builder(e.column, e.row)
        : _createTooltip(e.column, e.row));
    _hovercardRoot.style
      ..visibility = 'visible'
      ..opacity = '1.0';
    _updateTooltipPosition(evt: e);
  }

  void _handleMouseOut(ChartEvent e) {
    _ensureHovercard();
    _hovercardRoot.style
      ..visibility = 'hidden'
      ..opacity = '$EPSILON';
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
      _hovercardRoot.append(builder != null
          ? builder(value.first, value.last)
          : _createTooltip(value.first, value.last));
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
    _area.host.style.position = 'relative';
    _area.host.append(_hovercardRoot);
  }

  void _updateTooltipPosition({ChartEvent evt, int column, int row}) {
    assert(evt != null || column != null && row != null);
    if (_isMouseTracking && evt != null) {
      _positionAtMousePointer(evt);
    } else if (_area is CartesianArea) {
      if ((_area as CartesianArea).useTwoDimensionAxes) {
        _positionOnTwoDimensionCartesian(column, row);
      } else {
        _positionOnSingleDimensionCartesian(column, row);
      }
    } else {
      _positionOnLayout(column, row);
    }
  }

  void _positionAtMousePointer(ChartEvent e) =>
      _positionAtPoint(e.chartX, e.chartY, _HOVERCARD_OFFSET, _HOVERCARD_OFFSET, false, false);

  void _positionOnLayout(column, row) {
    // Currently for layouts, when hovercard is triggered due to change
    // in ChartState, we render hovercard in the middle of layout.
    // TODO: Get bounding rect from LayoutRenderer and position relative to it.
  }

  void _positionOnTwoDimensionCartesian(int column, int row) {
    // TODO: Implement multi dimension positioning.
  }

  void _positionOnSingleDimensionCartesian(int column, int row) {
    CartesianArea area = _area;
    var dimensionCol = area.config.dimensions.first,
        dimensionScale = area.dimensionScales.first,
        measureScale = _getScaleForColumn(column),
        dimensionOffset = _HOVERCARD_OFFSET,
        dimensionCenterOffset = 0;

    // If we are using bands on the one axis that is shown
    // update position and offset accordingly.
    if (area.dimensionsUsingBands.contains(dimensionCol)) {
      assert(dimensionScale is OrdinalScale);
      dimensionOffset = (dimensionScale as OrdinalScale).rangeBand ~/ 2;
      dimensionCenterOffset = dimensionOffset;
    }

    var rowData = area.data.rows.elementAt(row),
        measurePosition = 0,
        isNegative = false,
        dimensionPosition = dimensionScale
                .scale(rowData.elementAt(dimensionCol)) +
            dimensionCenterOffset;

    if (_isMultiValue) {
      var max = SMALL_INT_MIN, min = SMALL_INT_MAX;
      area.config.series.forEach((ChartSeries series) {
        CartesianRenderer renderer = series.renderer;
        Extent extent = renderer.extentForRow(rowData);
        if (extent.min < min) min = extent.min;
        if (extent.max > max) max = extent.max;
        measurePosition = measureScale.scale(max);
        isNegative = max < 0;
      });
    } else {
      var value = rowData.elementAt(column);
      if (value != null) {
        isNegative = value < 0;
        measurePosition = measureScale.scale(value);
      }
    }

    if (area.config.isLeftAxisPrimary) {
      _positionAtPoint(measurePosition, dimensionPosition, _HOVERCARD_OFFSET,
          dimensionOffset, isNegative, true);
    } else {
      _positionAtPoint(dimensionPosition, measurePosition, dimensionOffset,
          _HOVERCARD_OFFSET, isNegative, false);
    }
  }

  void _positionAtPoint(num x, num y, num xBand, num yBand, bool negative,
      [bool isLeftPrimary = false]) {
    var rect = _hovercardRoot.getBoundingClientRect(),
        width = rect.width,
        height = rect.height,
        scaleToHostY = (_area.theme.padding != null
                ? _area.theme.padding.top
                : 0) +
            (_area.layout.renderArea.y),
        scaleToHostX = (_area.theme.padding != null
                ? _area.theme.padding.start
                : 0) +
            (_area.layout.renderArea.x),
        renderAreaHeight = _area.layout.renderArea.height,
        renderAreaWidth = _area.layout.renderArea.width;

    if (scaleToHostY < 0) scaleToHostY = 0;
    if (scaleToHostX < 0) scaleToHostX = 0;

    num top = 0, left = 0;
    for (int i = 0, len = placementOrder.length; i < len; ++i) {
      String placement = placementOrder.elementAt(i);

      // Place the popup based on the orientation.
      if (placement == 'orientation') {
        placement = isLeftPrimary ? 'right' : 'top';
      }

      if (placement == 'top') {
        top = negative ? y + yBand : y - (height + yBand);
        left = isLeftPrimary ? x - width : x - width / 2;
      }
      if (placement == 'right') {
        top = isLeftPrimary ? y - height / 2 : y;
        left = negative ? x - (width + xBand) : x + xBand;
      }
      if (placement == 'left') {
        top = isLeftPrimary ? y - height / 2 : y;
        left = negative ? x + xBand : x - (width + xBand);
      }
      if (placement == 'bottom') {
        top = negative ? y - (height + yBand) : y + yBand;
        left = isLeftPrimary ? x - width : x - width / 2;
      }

      // Check if the popup is contained in the RenderArea.
      // If not, try other placements.
      if (top >= 0 &&
          left >= 0 &&
          top + height < renderAreaHeight &&
          left + width < renderAreaWidth) {
        break;
      }
    }

    _hovercardRoot.style
      ..top = '${top + scaleToHostY}px'
      ..left = '${left + scaleToHostX}px';
  }

  Element _createTooltip(int column, int row) {
    var element = new Element.div();
    if (_showDimensionTitle) {
      var titleElement = new Element.div()
        ..className = 'hovercard-title'
        ..text = _getDimensionTitle(column, row);
      element.append(titleElement);
    }

    var measureVals = _getMeasuresData(column, row);
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

      measureElement.className = _columnsToShow.length > 1 || _isMultiValue
          ? 'hovercard-measure hovercard-multi'
          : 'hovercard-measure hovercard-single';
      element.append(measureElement);
    });

    return element;
  }

  Iterable<ChartLegendItem> _getMeasuresData(int column, int row) {
    var measureVals = <ChartLegendItem>[];

    if (_columnsToShow.isNotEmpty) {
      _columnsToShow.forEach((int column) {
        measureVals.add(_createHovercardItem(column, row));
      });
    } else if (_columnsToShow.length > 1 || _isMultiValue) {
      var displayedCols = [];
      _area.config.series.forEach((ChartSeries series) {
        series.measures.forEach((int column) {
          if (!displayedCols.contains(column)) displayedCols.add(column);
        });
      });
      displayedCols.sort();
      displayedCols.forEach((int column) {
        measureVals.add(_createHovercardItem(column, row));
      });
    } else {
      measureVals.add(_createHovercardItem(column, row));
    }

    return measureVals;
  }

  ChartLegendItem _createHovercardItem(int column, int row) {
    var rowData = _area.data.rows.elementAt(row),
        columns = _area.data.columns,
        spec = columns.elementAt(column),
        colorKey = _area.useRowColoring ? row : column,
        formatter = _getFormatterForColumn(column),
        label = _area.useRowColoring
            ? rowData.elementAt(_area.config.dimensions.first)
            : spec.label;
    return new ChartLegendItem(
        label: label,
        value: formatter(rowData.elementAt(column)),
        color: _area.theme.getColorForKey(colorKey));
  }

  String _getDimensionTitle(int column, int row) {
    var rowData = _area.data.rows.elementAt(row),
        colSpec = _area.data.columns.elementAt(column);
    if (_area.useRowColoring) {
      return colSpec.label;
    } else {
      var count = (_area as CartesianArea).useTwoDimensionAxes ? 2 : 1,
          dimensions = _area.config.dimensions.take(count);
      return dimensions
          .map((int c) => _getFormatterForColumn(c)(rowData.elementAt(c)))
          .join(', ');
    }
  }

  // TODO: Move this to a common place?
  Scale _getScaleForColumn(int column) {
    var series = _area.config.series.firstWhere(
        (ChartSeries x) => x.measures.contains(column),
        orElse: () => null);
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
      // Formatter function must return String.  Default to identity function
      // but return the toString() instead.
      formatter = (x) => x.toString();
    }
    return formatter;
  }
}
