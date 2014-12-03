/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartAxis {
  static const List _VERTICAL_ORIENTATIONS =
      const [ ORIENTATION_LEFT, ORIENTATION_RIGHT ];

  _ChartArea area;
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
  Selection _group;

  EditableRect size;

  _ChartAxis.withAxisConfig(this.area, this.config);
  _ChartAxis(this.area);

  void initAxisDomain(int column, bool isDimension, Iterable domain) {
    _columnSpec = area.data.columns.elementAt(column);
    _column = column;
    _domain = domain;
    _isDimension = isDimension;
    if (scale == null) _scale = _columnSpec.createDefaultScale();
  }

  void initAxisScale(Iterable range, ChartAxisTheme theme) {
    assert(scale != null);

    // Sets the domain if not using a custom scale.
    if (config == null || (config != null && config.scale == null)) {
      scale.domain = _domain;
      scale.nice(theme.axisTickCount);
    }

    // Sets the range if not using a custom scale, or the custom scale uses
    // default range.
    /* TODO(prsd): Scale needs some cleanup */
    if (scale is OrdinalScale) {
      var usingBands = area.dimensionsUsingBands.contains(_column),
          innerPadding = usingBands ? theme.axisBandInnerPadding : 1.0,
          outerPadding = usingBands ?
              theme.axisBandOuterPadding : theme.axisOuterPadding;
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

    if (false && _theme.axisAutoResize) {
      /* TODO(prsd): Implement axis size computations */
    } else {
      var width = _isVertical ?
          _theme.verticalAxisWidth : area.layout.chartArea.width;
      var height = _isVertical ?
          area.layout.chartArea.height : _theme.horizontalAxisHeight;
      size = new EditableRect.size(width, height);
    }
  }

  void draw(GElement element) {
    assert(element != null && element is GElement);
    assert(scale != null);

    var rect = area.layout.axes[_orientation],
        renderAreaRect = area.layout.renderArea,
        range =  _isVertical ? [rect.height, 0] : [0, rect.width],
        className = (_isVertical ? 'vertical-axis': 'horizontal-axis');

    element.attributes['transform'] = 'translate(${rect.x}, ${rect.y})';

    if (_axis == null || _element != element) {
      _element = element;
      _axis = new SvgAxis()
          ..orientation = _orientation
          ..suggestedTickCount = _theme.axisTickCount
          ..tickPadding = _theme.axisTickPadding
          ..outerTickSize = 0
          ..tickFormat = _columnSpec.formatter;

      if (config != null && config.tickValues != null) {
        _axis.tickValues = config.tickValues;
      }

      _scope = new SelectionScope.element(_element);
      _group = _scope.selectElements([_element]);
    }
    
    _axis.innerTickSize = _theme.axisTickSize;
    if (_axis.innerTickSize <= ChartAxisTheme.FILL_RENDER_AREA) {
      _axis.innerTickSize =
          0 - (_isVertical ? renderAreaRect.width : renderAreaRect.height);
    }
    initAxisScale(range, _theme);
    if (_axis.scale != scale) _axis.scale = scale;
    _axis.axis(_group);
  }

  void clear() {
  }

  // Scale passed through configuration takes precedence
  Scale get scale =>
      (config != null && config.scale != null) ? config.scale : _scale;

  set scale(Scale value) => _scale = value;
}
