/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartAxis implements ChartAxis {
  bool isOrdinalScale = false;
  bool usingRangeBands = false;
  bool isMeasureAxis = false;

  int ticks;
  String orientation;

  GElement _host;
  Selection _group;
  Iterable _domain;

  Scale _scale;
  SvgAxis _axis;
  SelectionScope _scope;
  Formatter _tickFormatter;

  double innerPadding;
  double outerPadding;

  _ChartAxis(int this.ticks);

  set domain(Iterable value) {
    assert(value != null);
    assert(isOrdinalScale && value.length >= 1 || value.length >= 2);

    _domain = value;
  }
  get domain => _domain;

  set scale(Scale value) => _scale = value;
  Scale get scale => _scale;

  set tickFormatter(Formatter value) => _tickFormatter = value;
  Formatter get tickFormatter => _tickFormatter;

  void draw(ChartArea area, Element element) {
    assert(element != null && element is GElement);
    assert(scale != null);

    var width = int.parse(element.attributes['width']),
        height = int.parse(element.attributes['height']),
        isHorizontal = (orientation == ChartAxis.ORIENTATION_BOTTOM ||
            orientation == ChartAxis.ORIENTATION_TOP),
        range =  (isHorizontal ? [0, width] : [height, 0]),
        className = (isHorizontal ? 'horizontal-axis': 'vertical-axis'),
        theme = area.theme;

    if (_axis == null || _host != element) {
      int tickSize = isMeasureAxis ?
          theme.measureTickSize : theme.dimensionTickSize;
      if (tickSize <= ChartTheme.FULL_LENGTH_TICK) {
        tickSize = 0 - (isHorizontal ? area.yAxisHeight : area.xAxisWidth);
      }

      _host = element;
      _axis = new SvgAxis()
          ..orientation = orientation
          ..suggestedTickCount = this.ticks
          ..tickPadding = isMeasureAxis ?
              theme.measureTickPadding : theme.dimensionTickPadding
          ..innerTickSize = tickSize
          ..outerTickSize = 0;

      _scope = new SelectionScope.element(_host);
      _group = _scope.selectElements([_host]);

      if (tickFormatter != null) _axis.tickFormat = tickFormatter;
    }

    _scale.domain = _domain;
    _scale.nice(this.ticks);
    if (isOrdinalScale) {
      (_scale as OrdinalScale)
          .rangeRoundBands(range, innerPadding, outerPadding);
    } else {
      _scale.range = range;
    }

    if (_axis.scale != scale) _axis.scale = scale;
    _axis.axis(_group);
  }
}
