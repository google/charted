//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class _ChartAxis {
  static const List _VERTICAL_ORIENTATIONS =
      const [ ORIENTATION_LEFT, ORIENTATION_RIGHT ];

  _CartesianArea area;
  ChartAxisConfig config;
  ChartAxisTheme _theme;

  int _column;
  Iterable _domain;
  bool _isDimension;
  ChartColumnSpec _columnSpec;

  GElement _element;
  SvgAxis _axis;

  bool _isVertical;
  String _orientation;
  Scale _scale;
  SelectionScope _scope;

  MutableRect size;

  _ChartAxis.withAxisConfig(this.area, this.config);
  _ChartAxis(this.area);

  void initAxisDomain(int column, bool isDimension, Iterable domain) {
    _columnSpec = area.data.columns.elementAt(column);
    _column = column;
    _domain = domain;
    _isDimension = isDimension;

    // If we don't have a scale yet, create one.
    if (scale == null) {
      _scale = _columnSpec.createDefaultScale();
    }

    // Sets the domain if not using a custom scale.
    if (config == null || (config != null && config.scale == null)) {
      scale.domain = _domain;
      scale.nice = !_isDimension;
    }
  }

  void initAxisScale(Iterable range, ChartAxisTheme theme) {
    assert(scale != null);
    if (scale is OrdinalScale) {
      var usingBands = area.dimensionsUsingBands.contains(_column),
          innerPadding = usingBands ? theme.axisBandInnerPadding : 1.0,
          outerPadding = usingBands ?
              theme.axisBandOuterPadding : theme.axisOuterPadding;

      // This is because when left axis is primary the first data row should
      // appear on top of the y-axis instead of on bottom.
      if (area.config.isLeftAxisPrimary) {
        range = range.toList().reversed;
      }
      (scale as OrdinalScale).
          rangeRoundBands(range, innerPadding, outerPadding);
    } else {
      scale.range = range;
    }
  }

  void prepareToDraw(String orientation, ChartAxisTheme theme) {
    if (orientation == null) orientation = ORIENTATION_BOTTOM;
    _theme = theme;
    _orientation = orientation;
    _isVertical = _orientation == ORIENTATION_LEFT ||
        _orientation == ORIENTATION_RIGHT;

    var layout = area.layout.chartArea;
    if (_isVertical && _theme.verticalAxisAutoResize) {
      size = new MutableRect.size(_theme.verticalAxisWidth, layout.width);
    } else {
      size = _isVertical
          ? new MutableRect.size(_theme.verticalAxisWidth, layout.width)
          : new MutableRect.size(layout.height, _theme.horizontalAxisHeight);
    }

    if (_axis == null) {
      _axis = new SvgAxis(_orientation)
        ..tickPadding = _theme.axisTickPadding
        ..outerTickSize = 0
        ..tickFormat = _columnSpec.formatter;

      if (config != null && config.tickValues != null) {
        _axis.tickValues = config.tickValues;
      }
    }

    // Handle auto re-sizing of horizontal axis.
    if (_isVertical && theme.verticalAxisAutoResize &&
        !isNullOrEmpty(theme.ticksFont)) {
      var tickValues = (config != null && !isNullOrEmpty(config.tickValues))
              ? config.tickValues
              : scale.ticks,
          formatter = _columnSpec.formatter == null
              ? scale.createTickFormatter()
              : _columnSpec.formatter,
          textMetrics = new TextMetrics(fontStyle:theme.ticksFont),
          formatted = tickValues.map((x) => formatter(x)).toList();

      var width = textMetrics.getLongestTextWidth(formatted).ceil();
      if (width > theme.verticalAxisWidth) {
        width = theme.verticalAxisWidth;
        for (int i = 0, len = formatted.length; i < len; ++i) {
          formatted[i] =
              textMetrics.ellipsizeText(formatted[i], width.toDouble());
        }
        _axis.tickValues = formatted;
        _axis.tickFormat = (x) => x;
      } else {
        _axis.tickFormat = _columnSpec.formatter;
        _axis.tickValues = tickValues;
      }
      size.width =
          width + _theme.axisTickPadding + math.max(_theme.axisTickSize, 0);
    }
  }

  void draw(GElement element, {bool preRender: false}) {
    assert(element != null && element is GElement);
    assert(scale != null);

    var rect = area.layout.axes[_orientation],
        renderAreaRect = area.layout.renderArea,
        range =  _isVertical ? [rect.height, 0] : [0, rect.width],
        className = (_isVertical ? 'vertical-axis': 'horizontal-axis');

    element.attributes['transform'] = 'translate(${rect.x}, ${rect.y})';
    if (_element != element) {
      _element = element;
      _scope = new SelectionScope.element(_element);
    }

    _axis.innerTickSize = _theme.axisTickSize;
    if (_axis.innerTickSize <= ChartAxisTheme.FILL_RENDER_AREA) {
      _axis.innerTickSize =
          0 - (_isVertical ? renderAreaRect.width : renderAreaRect.height);
    }
    initAxisScale(range, _theme);
    if (_axis.scale != scale) _axis.scale = scale;
    _axis.create(_element, _scope,
        rect: rect, font: _theme.ticksFont, isRTL: area.config.isRTL);
  }

  void clear() {
  }

  // Scale passed through configuration takes precedence
  Scale get scale =>
      (config != null && config.scale != null) ? config.scale : _scale;

  set scale(Scale value) => _scale = value;
}
