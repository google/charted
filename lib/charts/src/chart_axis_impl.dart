//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class DefaultChartAxisImpl {
  static const int _AXIS_TITLE_HEIGHT = 20;

  CartesianArea _area;
  ChartAxisConfig config;
  ChartAxisTheme _theme;
  SvgAxisTicks _axisTicksPlacement;

  int _column;
  bool _isDimension;
  ChartColumnSpec _columnSpec;

  bool _isVertical;
  String _orientation;
  Scale _scale;
  SelectionScope _scope;
  String _title;

  MutableRect size;

  DefaultChartAxisImpl.withAxisConfig(this._area, this.config);
  DefaultChartAxisImpl(this._area);

  void initAxisDomain(int column, bool isDimension, Iterable domain) {
    _columnSpec = _area.data.columns.elementAt(column);
    _column = column;
    _isDimension = isDimension;

    // If we don't have a scale yet, create one.
    if (scale == null) {
      _scale = _columnSpec.createDefaultScale();
    }

    // We have the scale, get theme.
    _theme = isDimension
        ? _area.theme.getDimensionAxisTheme(scale)
        : _area.theme.getMeasureAxisTheme(scale);

    // Sets the domain if not using a custom scale.
    if (config == null || (config != null && config.scale == null)) {
      scale.domain = domain;
      scale.nice = !_isDimension &&
          !(config?.forcedTicksCount != null && config.forcedTicksCount > 0);
    }

    _title = config?.title;
  }

  void initAxisScale(Iterable range) {
    assert(scale != null);
    if (scale is OrdinalScale) {
      var usingBands = _area.dimensionsUsingBands.contains(_column),
          innerPadding = usingBands ? _theme.axisBandInnerPadding : 1.0,
          outerPadding =
          usingBands ? _theme.axisBandOuterPadding : _theme.axisOuterPadding;

      // This is because when left axis is primary the first data row should
      // appear on top of the y-axis instead of on bottom.
      if (_area.config.isLeftAxisPrimary) {
        range = range.toList().reversed;
      }
      (scale as OrdinalScale)
          .rangeRoundBands(range, innerPadding, outerPadding);
    } else {
      if (_title != null) {
        var modifiedRange = range.take(range.length - 1).toList();
        modifiedRange.add(range.last + _AXIS_TITLE_HEIGHT);
        scale.range = modifiedRange;
      } else {
        scale.range = range;
      }
      scale.ticksCount = _theme.axisTickCount;
    }
  }

  void prepareToDraw(String orientation) {
    if (orientation == null) orientation = ORIENTATION_BOTTOM;
    _orientation = orientation;
    _isVertical =
        _orientation == ORIENTATION_LEFT || _orientation == ORIENTATION_RIGHT;

    var layout = _area.layout.chartArea;
    size = _isVertical
        ? new MutableRect.size(_theme.verticalAxisWidth, layout.width)
        : new MutableRect.size(layout.height, _theme.horizontalAxisHeight);

    if (config?.forcedTicksCount != null && config.forcedTicksCount > 0) {
      scale.forcedTicksCount = config.forcedTicksCount;
    }

    // Handle auto re-sizing of horizontal axis.
    var ticks = (config != null && !isNullOrEmpty(config.tickValues))
        ? config.tickValues
        : scale.ticks,

    formatter = _columnSpec.formatter == null
        ? scale.createTickFormatter()
        : _columnSpec.formatter,
    textMetrics = new TextMetrics(fontStyle: _theme.ticksFont),
    formattedTicks = ticks.map((x) => formatter(x)).toList(),
    shortenedTicks = formattedTicks;
    if (_isVertical) {
      var width = textMetrics.getLongestTextWidth(formattedTicks).ceil();
      if (width > _theme.verticalAxisWidth) {
        width = _theme.verticalAxisWidth;
        shortenedTicks = formattedTicks
            .map((x) => textMetrics.ellipsizeText(x, width))
            .toList();
      }
      if (_theme.verticalAxisAutoResize) {
        size.width =
            width + _theme.axisTickPadding + math.max(_theme.axisTickSize, 0);
      }

      _axisTicksPlacement =
          new PrecomputedAxisTicks(ticks, formattedTicks, shortenedTicks);
    } else {
      // Precompute if extra room is needed for rotated label.
      var width = layout.width -
          _area.layout.axes[ORIENTATION_LEFT].width -
          _area.layout.axes[ORIENTATION_RIGHT].width;
      var allowedWidth = width ~/ ticks.length,
          maxLabelWidth = textMetrics.getLongestTextWidth(formattedTicks);
      if (!RotateHorizontalAxisTicks.needsLabelRotation(
          allowedWidth, maxLabelWidth)) {
        size.height = textMetrics.fontSize * 2;
      }
    }
  }

  void draw(Element element, SelectionScope scope, {bool preRender: false}) {
    assert(element != null && element is GElement);
    assert(scale != null);

    var rect = _area.layout.axes[_orientation],
        renderAreaRect = _area.layout.renderArea,
        range = _isVertical ? [rect.height, 0] : [0, rect.width],
        innerTickSize = _theme.axisTickSize <= ChartAxisTheme.FILL_RENDER_AREA
            ? 0 - (_isVertical ? renderAreaRect.width : renderAreaRect.height)
            : _theme.axisTickSize,
        tickValues = config != null && !isNullOrEmpty(config.tickValues)
            ? config.tickValues
            : null;

    element.attributes['transform'] = 'translate(${rect.x}, ${rect.y})';

    if (!_isVertical) {
      _axisTicksPlacement = new RotateHorizontalAxisTicks(
          rect, _theme.ticksFont, _theme.axisTickSize + _theme.axisTickPadding);
    }
    initAxisScale(range);

    if (_title != null) {
      var label = element.querySelector('.chart-axis-label');
      if (label != null) {
        label.text = _title;
      } else {
        var title = Namespace.createChildElement('text', element);
        title.attributes['text-anchor'] = 'middle';
        title.text = _title;
        title.classes.add('chart-axis-label');
        element.append(title);
      }
    }

    var axis = new SvgAxis(
        orientation: _orientation,
        innerTickSize: innerTickSize,
        outerTickSize: 0,
        tickPadding: _theme.axisTickPadding,
        tickFormat: _columnSpec.formatter,
        tickValues: tickValues,
        scale: scale);

    axis.create(element, scope,
        axisTicksBuilder: _axisTicksPlacement, isRTL: _area.config.isRTL);
  }

  void clear() {}

  // Scale passed through configuration takes precedence
  Scale get scale =>
      (config != null && config.scale != null) ? config.scale : _scale;

  set scale(Scale value) {
    _scale = value;
  }

}

class PrecomputedAxisTicks implements SvgAxisTicks {
  final int rotation = 0;
  final Iterable ticks;
  final Iterable formattedTicks;
  final Iterable shortenedTicks;
  const PrecomputedAxisTicks(
      this.ticks, this.formattedTicks, this.shortenedTicks);
  void init(SvgAxis axis) {}
}

class RotateHorizontalAxisTicks implements SvgAxisTicks {
  final Rect rect;
  final String ticksFont;
  final int tickLineLength;

  int rotation = 0;
  Iterable ticks;
  Iterable<String> formattedTicks;
  Iterable shortenedTicks;

  RotateHorizontalAxisTicks(this.rect, this.ticksFont, this.tickLineLength);

  static bool needsLabelRotation(num allowedWidth, num maxLabelWidth) =>
      0.90 * allowedWidth < maxLabelWidth;

  void init(SvgAxis axis) {
    assert(axis.orientation == ORIENTATION_BOTTOM ||
        axis.orientation == ORIENTATION_TOP);
    assert(ticksFont != null);
    ticks = axis.tickValues;
    formattedTicks = ticks.map((x) => axis.tickFormat(x)).toList();
    shortenedTicks = formattedTicks;

    var range = axis.scale.rangeExtent,
        textMetrics = new TextMetrics(fontStyle: ticksFont),
        allowedWidth = (range.max - range.min) ~/ ticks.length,
        maxLabelWidth = textMetrics.getLongestTextWidth(formattedTicks);

    // Check if we need rotation
    if (needsLabelRotation(allowedWidth, maxLabelWidth)) {
      var rectHeight =
          tickLineLength > 0 ? rect.height - tickLineLength : rect.height;
      rotation = 45;

      // Check if we have enough space to render full chart
      allowedWidth = (1.4142 * (rectHeight)) - (textMetrics.fontSize / 1.4142);
      if (maxLabelWidth > allowedWidth) {
        shortenedTicks = formattedTicks
            .map((x) => textMetrics.ellipsizeText(x, allowedWidth))
            .toList();
      }
    }
  }
}
