//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// A behavior that draws marking lines on the chart.
class LineMarker implements ChartBehavior {
  /// Position of the line markers.
  final Map<int, dynamic> positions;

  /// If true, the markers are drawn above the series
  final bool drawAboveSeries;

  /// If true, animates (grows from the axis into the chart)
  final bool animate;

  CartesianArea _area;
  bool _isLeftAxisPrimary = false;
  Rect _rect;

  bool _showing;
  Selection _parent;
  DataSelection _markers;

  StreamSubscription _axesChangeSubscription;

  LineMarker(this.positions,
      {this.drawAboveSeries: false, this.animate: false});

  void init(ChartArea area, Selection upper, Selection lower) {
    if (area is! CartesianArea) return;
    _area = area;
    _parent = drawAboveSeries ? upper : lower;
    _isLeftAxisPrimary = _area.config.isLeftAxisPrimary;
    _axesChangeSubscription = _area.onChartAxesUpdated.listen((_) => _update());
    _update();
  }

  void dispose() {
    if (_axesChangeSubscription != null) _axesChangeSubscription.cancel();
    if (_markers != null) _markers.remove();
  }

  bool _isDimension(int column) => _area.config.dimensions.contains(column);

  String _pathForDimension(int column, bool initial) {
    assert(_isDimension(column));

    int index;
    for (index = 0;
        _area.config.dimensions.elementAt(index) != column;
        ++index);

    assert(index == 0 || index == 1 && _area.useTwoDimensionAxes);

    var dimensionAtBottom =
        index == 1 && _isLeftAxisPrimary || index == 0 && !_isLeftAxisPrimary,
        scale = _area.dimensionScales.elementAt(index),
        scaled = scale.scale(positions[column]),
        theme = _area.theme.getDimensionAxisTheme(),
        renderAreaRect = _area.layout.renderArea,
        left = renderAreaRect.x,
        right = initial ? left : (left + renderAreaRect.width),
        bottom = renderAreaRect.y + renderAreaRect.height,
        top = initial ? bottom : renderAreaRect.y;

    if (scale is OrdinalScale) {
      var band = scale.rangeBand, bandPadding = theme.axisBandInnerPadding;
      scaled = scaled - band * bandPadding + _area.theme.defaultStrokeWidth;
      band = band + 2 * (band * bandPadding - _area.theme.defaultStrokeWidth);
      return dimensionAtBottom
          ? 'M ${left + scaled} ${bottom} V ${top} H ${left + scaled + band} V ${bottom} Z'
          : 'M ${left} ${scaled + band} H ${right} V ${scaled - band} H ${left} Z';
    } else {
      return dimensionAtBottom
          ? 'M ${left + scaled} ${bottom} V ${top}'
          : 'M ${left} ${scaled} H ${right}';
    }
  }

  String _pathForMeasure(int column, bool initial) {
    throw new UnimplementedError('Measure axis markers');
  }

  String _getMarkerPath(int column, bool initial) => _isDimension(column)
      ? _pathForDimension(column, initial)
      : _pathForMeasure(column, initial);

  void _update() {
    if (!_area.isReady) return;
    _markers = _parent.selectAll('.line-marker').data(positions.keys);

    _markers.enter.append('path').each((d, i, e) {
      e.classes.add('line-marker');
      e.attributes['d'] = _getMarkerPath(d, animate);
    });

    if (animate) {
      _markers
          .transition()
          .attrWithCallback('d', (d, i, e) => _getMarkerPath(d, false));
    }

    _markers.exit.remove();
  }
}
