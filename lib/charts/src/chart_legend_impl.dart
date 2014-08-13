
part of charted.charts;

class _ChartLegend implements ChartLegend {
  Element host;
  SelectionScope _scope;
  Selection _selected;

  _ChartLegend(Element this.host) {
    assert(host != null);
  }

  update(Iterable<ChartLegendItem> items, ChartArea chart) {
    assert(items != null);

    if (_scope == null) {
      _scope = new SelectionScope.element(host);
      _selected = _scope.selectElements([host]);
    }

    var rows = _selected.selectAll('.legend-row')
        .data(items, (ChartLegendItem item) => item.label);

    var columns = chart.data.columns;
    rows.enter.appendWithCallback((d, i, e) {
      Element row = new Element.tag('div')
          ..append(new Element.tag('div')
              ..className = 'legend-color')
          ..append(new Element.tag('div')
              ..className = 'legend-column');
      return row;
    });

    rows.classed('legend-row');
    rows.exit.remove();

    // This is needed to update legend colors when a column is removed or
    // inserted not at the tail of the list of ChartLegendItem.
    _selected.selectAll('.legend-color').data(items).styleWithCallback(
        'background-color', (d, i, c) => d.color);

    _selected.selectAll('.legend-column').data(items)
        ..textWithCallback((d, i, e) => d.label);
  }
}
