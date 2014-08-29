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
  ChartArea chartArea;
  Selection _tooltipSelection;
  StreamSubscription _valueMouseInSubscription;
  StreamSubscription _valueMouseOutSubscription;

  /**
   * Constructs the tooltip, display extra fields base on [config] and position
   * the tooltip base on [orientation] specified in the constructor.
   */
  ChartTooltip([this.showDimensionValue = false,
      this.showMeasureTotal = false, this.orientation = ORIENTATION_RIGHT]) {
  }

  /** Sets up listeners for triggering tooltip. */
  void init(ChartArea area, Element upperRenderPane, Element lowerRenderPane) {
    chartArea = area;
    var eventSource = area as ChartAreaEventSource;
    _valueMouseInSubscription = eventSource.onValueMouseOver.listen(show);
    _valueMouseOutSubscription = eventSource.onValueMouseOut.listen(hide);

    // Tooltip requires host to be position: relative.
    chartArea.host.style.position = 'relative';
    var _scope = new SelectionScope.element(chartArea.host);
    _scope.append('div')..classed('tooltip');
    _tooltipSelection = _scope.select('.tooltip');
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
      var dimensionColumn = chartArea.config.dimensions.elementAt(0);
      var dimensionValue = chartArea.data.rows.elementAt(e.row).elementAt(
          dimensionColumn);
      var dimensionValueFormatter = _getFormatterForColumn(dimensionColumn);
      _tooltipSelection.append('div')
        ..classed('tooltip-title')
        ..text((dimensionValueFormatter != null) ? dimensionValueFormatter(
            dimensionValue) : dimensionValue.toString());
    }

    // Display sum of the values in active row if set in config.
    if (showMeasureTotal) {
      var totalFormatFunc = _getFormatterForColumn(
          e.series.measures.elementAt(0));
      var total = 0;
      for (var i = 0; i < e.series.measures.length; i++) {
        total += chartArea.data.rows.elementAt(e.row).elementAt(
            e.series.measures.elementAt(i));
      }
      _tooltipSelection.append('div')
          ..classed('tooltip-total')
          ..text((totalFormatFunc != null) ? totalFormatFunc(total) :
              total.toString());
    }

    // Create the tooltip items base on the number of measures in the series.
    var items = _tooltipSelection.selectAll('.tooltip-item').data(
        e.series.measures);
    items.enter.append('div')
        ..classed('tooltip-item')
        ..classedWithCallback('active', (d, i, c) => (i == e.column));

    // Display the label for the currently active series.
    var tooltipItems = _tooltipSelection.selectAll('.tooltip-item');
    tooltipItems.append('div')
        ..classed('tooltip-item-label')
        ..textWithCallback((d, i, c) => chartArea.data.columns.elementAt(
            e.series.measures.elementAt(i)).label);

    // Display the value of the currently active series
    tooltipItems.append('div')
        ..classed('tooltip-item-value')
        ..styleWithCallback('color', (d, i, c) =>
            chartArea.theme.getColorForKey(d))
        ..textWithCallback((d, i, c) {
      var valueFormatter = _getFormatterForColumn(d);
      var value = chartArea.data.rows.elementAt(e.row).elementAt(d);
      return (valueFormatter != null) ? valueFormatter(value) :
          value.toString();
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

  /** Computes the ideal tooltip position base on orientation. */
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

    return boundTooltipPosition(new math.Rectangle(x, y, rect.width,
        rect.height));
  }

  /** Positions the tooltip to be inside of the window boundary. */
  math.Point boundTooltipPosition(math.Rectangle rect) {
    var hostRect = chartArea.host.getBoundingClientRect();
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

  FormatFunction _getFormatterForColumn(int column) {
    return chartArea.data.columns.elementAt(column).formatter;
  }

  hide(ChartEvent e) {
    if (_tooltipSelection == null) {
      return;
    }
    _tooltipSelection.style('opacity', '0');
  }

  void destroy() {
    if (_valueMouseInSubscription != null) _valueMouseInSubscription.cancel();
    if (_valueMouseOutSubscription != null) _valueMouseOutSubscription.cancel();
  }
}
