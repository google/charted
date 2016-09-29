//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// Displays tooltip for the values as user moves the mouse pointer over
/// values in the chart. It displays all the active values in the data row
/// and use the value in the dimension as the title.
@Deprecated('Use Hovercard')
class ChartTooltip implements ChartBehavior {
  static const _TOOLTIP_OFFSET = 10;
  final String orientation;
  final bool showDimensionValue;
  final bool showMeasureTotal;
  final bool showSelectedMeasure;

  ChartArea _area;
  ChartState _state;
  Selection _tooltipRoot;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  /// Constructs the tooltip.
  /// If [showDimensionValue] is set, displays the dimension value as title.
  /// If [showMeasureTotal] is set, displays the total value.
  ChartTooltip(
      {this.showSelectedMeasure: false,
      this.showDimensionValue: false,
      this.showMeasureTotal: false,
      this.orientation: ORIENTATION_RIGHT});

  /// Sets up listeners for triggering tooltip.
  void init(ChartArea area, Selection _, Selection __) {
    _area = area;
    _state = area.state;
    _disposer.addAll([
      area.onValueMouseOver.listen(show),
      area.onValueMouseOut.listen(hide)
    ]);

    // Tooltip requires host to be position: relative.
    area.host.style.position = 'relative';

    var _scope = new SelectionScope.element(_area.host);
    _scope.append('div')..classed('tooltip');
    _tooltipRoot = _scope.select('.tooltip');
  }

  void dispose() {
    _disposer.dispose();
    if (_tooltipRoot != null) _tooltipRoot.remove();
  }

  /// Displays tooltip upon receiving a hover event on an element in chart.
  show(ChartEvent e) {
    _tooltipRoot.first
      ..children.clear()
      ..attributes['dir'] = _area.config.isRTL ? 'rtl' : '';
    _tooltipRoot.classed('rtl', _area.config.isRTL);

    // Display dimension value if set in config.
    if (showDimensionValue) {
      var column = _area.config.dimensions.elementAt(0),
          value = _area.data.rows.elementAt(e.row).elementAt(column),
          formatter = _getFormatterForColumn(column);

      _tooltipRoot.append('div')
        ..classed('tooltip-title')
        ..text((formatter != null) ? formatter(value) : value.toString());
    }

    // Display sum of the values in active row if set in config.
    if (showMeasureTotal) {
      var measures = e.series.measures,
          formatter = _getFormatterForColumn(measures.elementAt(0)),
          row = _area.data.rows.elementAt(e.row),
          total = 0;
      for (int i = 0, len = measures.length; i < len; i++) {
        total += row.elementAt(measures.elementAt(i));
      }
      _tooltipRoot.append('div')
        ..classed('tooltip-total')
        ..text((formatter != null) ? formatter(total) : total.toString());
    }

    // Find the currently selectedMeasures and hoveredMeasures and show
    // tooltip for them, if none is selected/hovered, show all.
    var activeMeasures = [];
    if (showSelectedMeasure) {
      if (_state != null) {
        activeMeasures.addAll(_state.selection);
        activeMeasures.add(
            _state.preview != null ? _state.preview : _state.hovered.first);
      } else {
        // If state is null, chart tooltip will not capture selection, but only
        // display for the currently hovered measure column.
        activeMeasures.add(e.column);
      }
      if (activeMeasures.isEmpty) {
        for (var series in _area.config.series) {
          activeMeasures.addAll(series.measures);
        }
      }
      activeMeasures.sort();
    }

    var data = (showSelectedMeasure) ? activeMeasures : e.series.measures;

    // Create the tooltip items base on the number of measures in the series.
    var items = _tooltipRoot.selectAll('.tooltip-item').data(data);
    items.enter.append('div')
      ..classed('tooltip-item')
      ..classedWithCallback(
          'active', (d, i, c) => !showSelectedMeasure && (d == e.column));

    // Display the label for the currently active series.
    var tooltipItems = _tooltipRoot.selectAll('.tooltip-item');
    tooltipItems.append('div')
      ..classed('tooltip-item-label')
      ..textWithCallback((d, i, c) => _area.data.columns
          .elementAt((showSelectedMeasure) ? d : e.series.measures.elementAt(i))
          .label);

    // Display the value of the currently active series
    tooltipItems.append('div')
      ..classed('tooltip-item-value')
      ..styleWithCallback('color', (d, i, c) => _area.theme.getColorForKey(d))
      ..textWithCallback((d, i, c) {
        var formatter = _getFormatterForColumn(d),
            value = _area.data.rows.elementAt(e.row).elementAt(d);
        return (formatter != null) ? formatter(value) : value.toString();
      });

    math.Point position = computeTooltipPosition(
        new math.Point(e.chartX, e.chartY),
        _tooltipRoot.first.getBoundingClientRect());

    // Set position of the tooltip and display it.
    _tooltipRoot
      ..style('left', '${position.x}px')
      ..style('top', '${position.y}px')
      ..style('opacity', '1');
  }

  static String switchPositionDirection(String direction) =>
      direction == ORIENTATION_LEFT ? ORIENTATION_RIGHT : ORIENTATION_LEFT;

  /// Computes the ideal tooltip position based on orientation.
  math.Point computeTooltipPosition(math.Point coord, math.Rectangle rect) {
    var x, y, direction;
    direction = _area.config.isRTL && _area.config.switchAxesForRTL
        ? switchPositionDirection(orientation)
        : orientation;

    if (direction == ORIENTATION_LEFT) {
      x = coord.x - rect.width - _TOOLTIP_OFFSET;
      y = coord.y + _TOOLTIP_OFFSET;
    } else {
      x = coord.x + _TOOLTIP_OFFSET;
      y = coord.y + _TOOLTIP_OFFSET;
    }
    return boundTooltipPosition(
        new math.Rectangle(x as num, y as num, rect.width, rect.height));
  }

  /// Positions the tooltip to be inside of the chart boundary.
  math.Point boundTooltipPosition(math.Rectangle rect) {
    var hostRect = _area.host.getBoundingClientRect();

    var top = rect.top;
    var left = rect.left;

    // Checks top and bottom.
    if (rect.top < 0) {
      top += (2 * _TOOLTIP_OFFSET);
    } else if (rect.top + rect.height > hostRect.height) {
      top -= (rect.height + 2 * _TOOLTIP_OFFSET);
    }

    // Checks left and right.
    if (rect.left < 0) {
      left += (rect.width + 2 * _TOOLTIP_OFFSET);
    } else if (rect.left + rect.width > hostRect.width) {
      left -= (rect.width + 2 * _TOOLTIP_OFFSET);
    }

    return new math.Point(left, top);
  }

  FormatFunction _getFormatterForColumn(int column) =>
      _area.data.columns.elementAt(column).formatter;

  hide(ChartEvent e) {
    if (_tooltipRoot == null) return;
    _tooltipRoot.style('opacity', '0');
  }
}
