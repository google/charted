//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class _ChartLegend implements ChartLegend {
  static const CLASS_PREFIX = 'chart-legend';

  final Element host;
  final int _maxItems;
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  String _title;
  SelectionScope _scope;
  Selection _root;
  ChartArea _area;

  Iterable<ChartLegendItem> _items;

  _ChartLegend(Element this.host, int this._maxItems, String this._title) {
    assert(host != null);
  }

  void dispose() {
    _disposer.dispose();
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
      if (_root.select('.chart-legend-heading').length == 0) {
        _root.select('.chart-legend-heading');
        _root.append('div')
          ..classed('chart-legend-heading')
          ..text(_title);
      } else {
        _root.select('.chart-legend-heading').text(_title);
      }
    }
  }

  /** Updates the legend base on a new list of ChartLegendItems. */
  update(Iterable<ChartLegendItem> items, ChartArea area) {
    assert(items != null);
    assert(area == _area || _area == null);

    _area = area;
    if (_area.state != null) {
      _disposer.add(_area.state.changes.listen(_handleStateChanges));
    }
    if (_scope == null) {
      _scope = new SelectionScope.element(host);
      _root = _scope.selectElements([host]);
    }

    _updateTitle();
    _items = items;
    _createLegendItems();

    // Add more item label if there's more items than the max display items.
    if ((_maxItems > 0) && (_maxItems < items.length)) {
      _root.select('.chart-legend-more').remove();
      _root.append('div')
        ..on('mouseover', (d, i, e) => _displayMoreItem(items.skip(_maxItems)))
        ..on('mouseleave', (d, i, e) => _hideMoreItem())
        ..text('${items.length - _maxItems} more...')
        ..classed('chart-legend-more');
    }
  }

  /** Hides extra legend items. */
  void _hideMoreItem() {
    var tooltip = _root.select('.chart-legend-more-tooltip');
    tooltip.style('opacity', '0');
  }

  // Displays remaining legend items as a tooltip
  void _displayMoreItem(Iterable<ChartLegendItem> items) {
    var tooltip = _root.select('.chart-legend-more-tooltip');
    if (tooltip.isEmpty) {
      tooltip = _root.select('.chart-legend-more').append('div')
          ..classed('chart-legend-more-tooltip');
    }
    tooltip.style('opacity', '1');

    // _createLegendItems(tooltip, 'chart-legend-more', items);
  }

  /// Creates legend items starting at the given index.
  void _createLegendItems() {
    var state = _area.state,
        rows = _root.selectAll(
            '.${CLASS_PREFIX}-row').data(_items, (x) => x.hashCode),
        enter = rows.enter.appendWithCallback((d, i, e) =>
          new Element.html(
              '<div class="${CLASS_PREFIX}-row">'
                '<div class="${CLASS_PREFIX}-color"></div>'
                '<div class="${CLASS_PREFIX}-label"></div>'
              '</div>'));

    rows.each((ChartLegendItem d, i, Element e) {
      if (state != null) {
        if (d.index == state.preview) {
          e.classes.add('${CLASS_PREFIX}-hover');
        } else {
          e.classes.remove('${CLASS_PREFIX}-hover');
        }
        if (state.isSelected(d.index)) {
          e.classes.add('${CLASS_PREFIX}-selected');
        } else {
          e.classes.remove('${CLASS_PREFIX}-selected');
        }
      }
      (e.firstChild as Element).style.setProperty('background-color', d.color);
      (e.lastChild as Element).innerHtml = d.label;
    });

    if (state != null) {
      enter
        ..on('mouseover', (d, i, e) => state.preview = d.index)
        ..on('mouseout', (d, i, e) {
            if (state.preview == d.index) {
              state.preview = null;
            }
          })
        ..on('click', (d, i, e) {
            if (state.isSelected(d.index)) {
              state.unselect(d.index);
            } else {
              state.select(d.index);
            }
          });
    }

    rows.exit.remove();
  }

  /// Update legend to show chart's selection and visibility.
  void _handleStateChanges(_) => _createLegendItems();
}
