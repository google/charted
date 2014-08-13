part of charted.charts;

class StackedBarChartRenderer implements ChartRenderer {
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

    var rows = new List()..addAll(area.data.rows.map((e) {
      var row = [];
      for (var i = series.measures.length - 1; i >= 0; i--) {
        row.add(e[series.measures.elementAt(i)]);
      }
      return row;
    }));

    String color(i) =>
        area.theme.getColorForKey(
            series.measures.elementAt(series.measures.length - 1 - i));

    // We support only one dimension, so always use the first one.
    var x = area.data.rows.map(
        (row) => row.elementAt(area.config.dimensions.first)).toList();

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

    /* TODO(prsd): Handle cases where x and y axes are swapped */
    var bar = group.selectAll('.bar').dataWithCallback((d, i, c) => rows[i]);

    var ic = -1,
        order = 0,
        prevY = new List();

    prevY.add(0);
    bar.each((d, i, e) {
      if (i > ic) {
        prevY[prevY.length - 1] = e.attributes['y'];
      } else {
        prevY.add(e.attributes['y']);
      }
      ic = i;
    });

    ic = 1e100;
    var enter = bar.enter.append('rect')
        ..classed('bar')
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', dimensionScale.rangeBand - theme.defaultStrokeWidth)
        ..attrWithCallback('y', (d, i, c) {
            var tempY;
            if (i <= ic && i > 0) {
              tempY = prevY[order];
              order++;
            } else {
              tempY = geometry.height;
            }
            ic = i;
            return tempY;
          })
        ..attr('height', 0);

    bar.transition()
        ..styleWithCallback('fill', (d, i, c) => color(i))
        ..attr('width', dimensionScale.rangeBand - theme.defaultStrokeWidth)
        ..duration(theme.transitionDuration);

    var y = 0,
        length = bar.length;
    bar.transition()
        ..attrWithCallback('y', (d, i, c) {
            if (i == 0) y = measureScale.apply(0).round();
            return (y -= (geometry.height - measureScale.apply(d).round()));
          })
        ..attrWithCallback('height', (d, i, c) {
            var ht = geometry.height - measureScale.apply(d).round();
            if (i != 0) {
              ht -= (theme.defaultSeparatorWidth + theme.defaultStrokeWidth);
            }
            if (ht < 0) ht = 0;
            return ht;
          })
        ..duration(theme.transitionDuration)
        ..delay(50);

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

  double get bandInnerPadding =>
      area.theme.dimensionAxisTheme.axisBandInnerPadding;

  double get bandOuterPadding =>
      area.theme.dimensionAxisTheme.axisBandOuterPadding;

  Extent get extent {
    assert(area != null && series != null);
    var rows = area.data.rows,
        max = rows[0][series.measures.first],
        min = max;

    rows.forEach((row) {
      if (row[series.measures.first] < min)
        min = row[series.measures.first];

      var bar = 0;
      series.measures.forEach((idx) {
        bar += row[idx];
      });
      if (bar > max) max = bar;
    });

    return new Extent(min, max);
  }
}
