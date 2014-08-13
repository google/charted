part of charted.charts;

class LineChartRenderer implements ChartRenderer {
  final Iterable<int> dimensionsUsingBand = const[];

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
    assert(area != null && series != null);
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

    // Create initial values for transitiion
    var initialValues = series.measures.map((column) {
      return area.data.rows.map((values) => 0).toList();
    }).toList();

    // Create lists of values in measure columns.
    var lines = series.measures.map((column) {
      return area.data.rows.map((values) => values[column]).toList();
    }).toList();

    // We only support one dimension axes, so we always use the
    // first dimension.
    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

    var rangeBandOffset = dimensionScale.rangeBand / 2;
    var line = new SvgLine();
    line.xAccessor = (d, i) => dimensionScale.apply(x[i]) + rangeBandOffset;
    line.yAccessor = (d, i) => measureScale.apply(d);

    var product = _group.selectAll(".line").data(initialValues);
    product.enter.append("path")
        ..classed("line", true)
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color(i))
        ..style('fill', 'none');

    int delay = 0;
    product = _group.selectAll(".line").data(lines);
    product.transition()
        ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
        ..styleWithCallback('stroke', (d, i, e) => color(i))
        ..duration(theme.transitionDuration)
        ..delayWithCallback((d, i, c) => delay += 50 ~/ series.measures.length);
    product.exit.remove();
  }

  void clear() {
    if (_group == null) return;
    _group.selectAll('.line').remove();
  }

  double get bandInnerPadding => 1.0;
  double get bandOuterPadding =>
      area.theme.dimensionAxisTheme.axisOuterPadding;

  Extent get extent {
    assert(area != null && series != null);
    var rows = area.data.rows,
        max = rows[0][series.measures.first],
        min = max;

    rows.forEach((row) {
      series.measures.forEach((idx){
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }
}
