part of charted.charts;

/*
 * TODO(prsd): Move the common functionality into a base class
 * that we could inherit from.
 */

class BarChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[0];

  ChartArea area;
  ChartSeries series;

  Element _host;
  Selection _group;
  SelectionScope _scope;

  /*
   * Returns false if the number of dimension axes on the area is 0.
   * Otherwise, the first dimension scale is used to render the chart.
   */
  bool prepare(ChartArea area, ChartSeries series) {
    assert(area != null && series != null);
    if (area.dimensionAxesCount == 0) return false;
    this.area = area;
    this.series = series;
    return true;
  }

  void draw(Element element,
      Iterable<Scale> dimensions, Iterable<Scale> measures) {
    assert(series != null && area != null);
    assert(element != null && element is GElement);

    if (_scope == null) {
      _host = element;
      _scope = new SelectionScope.element(element);
      _group = _scope.selectElements([_host]);
    }

    var geometry = area.layout.renderArea,
        measuresCount = series.measures.length,
        measureScale = measures.first,
        dimensionScale = dimensions.first,
        theme = area.theme;

    String color(i) =>
        theme.getColorForKey(series.measures.elementAt(i));

    var rows = new List()..addAll(area.data.rows.map((e) {
      var row = [];
      for (var measure in series.measures) {
        row.add(e[measure]);
      }
      return row;
    }));

    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var bars = new OrdinalScale()
        ..domain = new Range(series.measures.length).toList()
        ..rangeRoundBands([0, dimensionScale.rangeBand]);

    var group = _group.selectAll('.row-group').data(rows);

    group.enter.append('g')
        ..classed('row-group')
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.apply(x[i])}, 0)');
    group.exit.remove();

    group.transition()
        ..attrWithCallback('transform', (d, i, c) =>
            'translate(${dimensionScale.apply(x[i])}, 0)')
        ..duration(theme.transitionDuration);

    int barWidth = bars.rangeBand -
        theme.defaultSeparatorWidth - theme.defaultStrokeWidth;

    var bar = group.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);
    var enter = bar.enter.append('rect')
        ..classed('bar')
        ..attr('y', geometry.height)
        ..attr('height', 0)
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attrWithCallback(
            'x', (d, i, c) => bars.apply(i) + theme.defaultStrokeWidth)
        ..attr('width', barWidth);

    bar.transition()
        ..attrWithCallback(
            'x', (d, i, c) => bars.apply(i) + theme.defaultStrokeWidth)
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', barWidth)
        ..duration(theme.transitionDuration);

    int delay = 0;
    bar.transition()
        ..attrWithCallback('y', (d, i, c) => measureScale.apply(d).round())
        ..attrWithCallback('height',
            (d, i, c) => geometry.height - measureScale.apply(d).round())
        ..delayWithCallback((d, i, c) =>
            delay += theme.transitionDuration ~/
              (series.measures.length * rows.length));

    if (theme.defaultStrokeWidth > 0) {
      enter.attr('stroke-width', '${theme.defaultStrokeWidth}px');
      enter.styleWithCallback('stroke', (d, i, c) => color(i));
      bar.transition()
        ..styleWithCallback('stroke', (d, i, c) => color(i));
    }

    bar.exit.remove();
  }

  void clear() {
    if (_group == null) return;
    _group.selectAll('.row-group').remove();
  }

  double get bandInnerPadding {
    assert(series != null && area != null);
    var measuresCount = series.measures.length;
    return measuresCount > 2 ? 1 - (measuresCount / (measuresCount + 1)) :
        area.theme.dimensionAxisTheme.axisBandInnerPadding;
  }

  double get bandOuterPadding {
    assert(series != null && area != null);
    return area.theme.dimensionAxisTheme.axisBandOuterPadding;
  }

  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
        max = rows[0][series.measures.first],
        min = max;

    rows.forEach((row) {
      series.measures.forEach((idx) {
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }
}
