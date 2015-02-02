/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartLegend implements ChartLegend {
  final Element host;
  final int _maxItems;
  String _title;
  SelectionScope _scope;
  Selection _selected;

  _ChartLegend(Element this.host, int this._maxItems, String this._title) {
    assert(host != null);
  }

  /**
   * Sets the title of the legend, if the legend is already drawn, updates the
   * title on the legend as well.
   */
  void set title(String title) {
    _title = title;
    if (_scope == null) return;
    _updateTitle();
  }

  String get title => _title;

  /** Updates the title of the legend. */
  void _updateTitle() {
    if (_title.isNotEmpty) {
      if (_selected.select('.legend-title').length == 0) {
        _selected.select('.legend-title');
        _selected.append('div')
          ..classed('legend-title')
          ..text(_title);
      } else {
        _selected.select('.legend-title').text(_title);
      }
    }
  }

  /** Updates the legend base on a new list of ChartLegendItems. */
  update(Iterable<ChartLegendItem> items, ChartArea chart) {
    assert(items != null);

    if (_scope == null) {
      _scope = new SelectionScope.element(host);
      _selected = _scope.selectElements([host]);
    }

    _updateTitle();

    _createLegendItems(_selected, 'legend',
        (_maxItems > 0) ? items.take(_maxItems) : items);

    // Add more item label if there's more items than the max display items.
    if ((_maxItems > 0) && (_maxItems < items.length)) {
      _selected.select('.legend-more').remove();
      _selected.append('div')
        ..on('mouseover', (d, i, e) => _displayMoreItem(items.skip(_maxItems)))
        ..on('mouseleave', (d, i, e) => _hideMoreItem())
        ..text('${items.length - _maxItems} more...')
        ..classed('legend-more');
    }
  }

  /** Hides extra legend items. */
  void _hideMoreItem() {
    var tooltip = _selected.select('.legend-more-tooltip');
    tooltip.style('opacity', '0');
  }

  /** Display more legend items. */
  void _displayMoreItem(Iterable<ChartLegendItem> items) {
    var tooltip = _selected.select('.legend-more-tooltip');
    if (tooltip.isEmpty) {
      tooltip = _selected.select('.legend-more').append('div')
          ..classed('legend-more-tooltip');
    }
    tooltip.style('opacity', '1');

    _createLegendItems(tooltip, 'legend-more', items);
  }

  /**
   * Creates a list of legend items base on the label of the [items], appending
   * legend item classes and prefix them with [classPrefix] and attatch the
   * items to [host].
   */
  void _createLegendItems(Selection host, String classPrefix,
      Iterable<ChartLegendItem> items) {
    var rows = host.selectAll('.${classPrefix}-row').data(items);
    rows.enter.appendWithCallback((d, i, e) {
      Element row = new Element.tag('div')
          ..append(new Element.tag('div')
              ..className = '${classPrefix}-color')
          ..append(new Element.tag('div')
              ..className = '${classPrefix}-column');
      return row;
    });

    rows.classed('${classPrefix}-row');
    rows.exit.remove();

    // This is needed to update legend colors when a column is removed or
    // inserted not at the tail of the list of ChartLegendItem.
    _selected.selectAll('.${classPrefix}-color').data(items).styleWithCallback(
        'background-color', (d, i, c) => d.color);

    _selected.selectAll('.${classPrefix}-column').data(items)
        ..textWithCallback((d, i, e) => d.label);
  }
}
