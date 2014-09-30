part of charted.charts;

/**
 * The ChartTooltip displays tooltip for the values being interacted with in the
 * chart.  It displays all the active values in the data row and use the value
 * in the dimension as the title.
 */
class ChartTooltip implements ChartBehavior {
  static const _TOOLTIP_OFFSET = 26;
  final String orientation;
  final bool showDimensionValue;
  final bool showMeasureTotal;

  ChartArea _area;
  Selection _tooltipSelection;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  /**
   * Constructs the tooltip, display extra fields base on [config] and position
   * the tooltip base on [orientation] specified in the constructor.
   */
  ChartTooltip({this.showDimensionValue: false,
      this.showMeasureTotal: false, this.orientation: ORIENTATION_RIGHT});

  /** Sets up listeners for triggering tooltip. */
  void init(ChartArea area, Element upperRenderPane, Element lowerRenderPane) {
    _area = area;
    _disposer.addAll([
        area.onValueMouseOver.listen(show),
        area.onValueMouseOut.listen(hide)
    ]);

    // Tooltip requires host to be position: relative.
    area.host.style.position = 'relative';

    var _scope = new SelectionScope.element(_area.host);
    _scope.append('div')..classed('tooltip');
    _tooltipSelection = _scope.select('.tooltip');
  }

  void dispose() {
    _disposer.dispose();
    if (_tooltipSelection != null) _tooltipSelection.remove();
  }

  /**
   * Displays the tooltip upon receiving a hover event on an element in the
   * chart.
   */
  show(ChartEvent e) {
    // Clear
    _tooltipSelection.first.children.clear();

    // Display dimension value if set in config.
    if (showDimensionValue) {
      var column = _area.config.dimensions.elementAt(0),
          value =
              _area.data.rows.elementAt(e.row).elementAt(column),
          formatter = _getFormatterForColumn(column);

      _tooltipSelection.append('div')
        ..classed('tooltip-title')
        ..text((formatter != null) ? formatter(value) : value.toString());
    }

    // Display sum of the values in active row if set in config.
    if (showMeasureTotal) {
      var formatter =
          _getFormatterForColumn(e.series.measures.elementAt(0));
      var total = 0;
      for (var i = 0; i < e.series.measures.length; i++) {
        total += _area.data.rows.elementAt(e.row).
            elementAt(e.series.measures.elementAt(i));
      }
      _tooltipSelection.append('div')
          ..classed('tooltip-total')
          ..text((formatter != null) ? formatter(total) : total.toString());
    }

    // Create the tooltip items base on the number of measures in the series.
    var items = _tooltipSelection.selectAll('.tooltip-item').
        data(e.series.measures);
    items.enter.append('div')
        ..classed('tooltip-item')
        ..classedWithCallback('active', (d, i, c) => (i == e.column));

    // Display the label for the currently active series.
    var tooltipItems = _tooltipSelection.selectAll('.tooltip-item');
    tooltipItems.append('div')
        ..classed('tooltip-item-label')
        ..textWithCallback((d, i, c) => _area.data.columns.
            elementAt(e.series.measures.elementAt(i)).label);

    // Display the value of the currently active series
    tooltipItems.append('div')
        ..classed('tooltip-item-value')
        ..styleWithCallback('color', (d, i, c) =>
            _area.theme.getColorForKey(d))
        ..textWithCallback((d, i, c) {
      var formatter = _getFormatterForColumn(d),
          value = _area.data.rows.elementAt(e.row).elementAt(d);
      return (formatter != null) ? formatter(value) : value.toString();
    });

    math.Point position = computeTooltipPosition(
        new math.Point(e.chartX + _ChartArea.MARGIN,
            e.chartY + _ChartArea.MARGIN),
            _tooltipSelection.first.getBoundingClientRect());

    // Set position of the tooltip and display it.
    _tooltipSelection
        ..style('left', '${position.x}px')
        ..style('top', '${position.y}px')
        ..style('opacity', '1');
  }

  /** Computes the ideal tooltip position based on orientation. */
  math.Point computeTooltipPosition(math.Point coord,
      math.Rectangle rect) {
    var x, y;
    if (orientation == ORIENTATION_TOP) {
      x = coord.x - rect.width / 2;
      y = coord.y - rect.height - _TOOLTIP_OFFSET;
    } else if (orientation == ORIENTATION_RIGHT) {
      x = coord.x + _TOOLTIP_OFFSET;
      y = coord.y - rect.height / 2;
    } else if (orientation == ORIENTATION_BOTTOM) {
      x = coord.x - rect.width / 2;
      y = coord.y + _TOOLTIP_OFFSET;
    } else { // left
      x = coord.x - rect.width - _TOOLTIP_OFFSET;
      y = coord.y - rect.height / 2;
    }

    return boundTooltipPosition(
        new math.Rectangle(x, y, rect.width, rect.height));
  }

  /** Positions the tooltip to be inside of the window boundary. */
  math.Point boundTooltipPosition(math.Rectangle rect) {
    var hostRect = _area.host.getBoundingClientRect();
    var windowWidth = window.innerWidth;
    var windowHeight = window.innerHeight;

    var top = rect.top;
    var left = rect.left;

    // Checks top and bottom.
    if (rect.top + hostRect.top < 0) {
      top = -hostRect.top;
    } else if (rect.top + rect.height + hostRect.top > windowHeight) {
      top = windowHeight - rect.height - hostRect.top;
    }

    // Checks left and right.
    if (rect.left < 0) {
      left = -hostRect.left;
    } else if (rect.left + rect.width + hostRect.left > windowWidth) {
      left = windowWidth - rect.width - hostRect.left;
    }

    return new math.Point(left, top);
  }

  FormatFunction _getFormatterForColumn(int column) =>
      _area.data.columns.elementAt(column).formatter;

  hide(ChartEvent e) {
    if (_tooltipSelection == null) return;
    _tooltipSelection.style('opacity', '0');
  }
}

