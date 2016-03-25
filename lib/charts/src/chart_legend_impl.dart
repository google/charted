//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class DefaultChartLegendImpl implements ChartLegend {
  static const CLASS_PREFIX = 'chart-legend';

  final Element host;
  final int visibleItemsCount;
  final bool showValues;
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  String _title;
  SelectionScope _scope;
  Selection _root;
  ChartArea _area;

  Iterable<ChartLegendItem> _items;

  DefaultChartLegendImpl(
      this.host, this.visibleItemsCount, this.showValues, String title)
      : _title = title {
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
    if ((visibleItemsCount > 0) && (visibleItemsCount < items.length)) {
      _root.select('.chart-legend-more').remove();
      _root.append('div')
        ..on('mouseover',
            (d, i, e) => _displayMoreItem(items.skip(visibleItemsCount)))
        ..on('mouseleave', (d, i, e) => _hideMoreItem())
        ..text('${items.length - visibleItemsCount} more...')
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
        rows =
        _root.selectAll('.chart-legend-row').data(_items, (x) => x.hashCode),
        isFirstRender = rows.length == 0;

    var enter = rows.enter.appendWithCallback((ChartLegendItem d, i, e) {
      var row = Namespace.createChildElement('div', e),
          color = Namespace.createChildElement('div', e)
            ..className = 'chart-legend-color',
          label = Namespace.createChildElement('div', e)
            ..className = 'chart-legend-label',
          value = showValues
              ? (Namespace.createChildElement('div', e)
                ..className = 'chart-legend-value')
              : null;

      var rowStyles = <String>['chart-legend-row'];

      // If this is the first time we are adding rows,
      // Update elements before adding them to the DOM.
      if (isFirstRender) {
        if (state != null) {
          if (d.index == state.preview) {
            rowStyles.add('chart-legend-hover');
          }
          if (state.isSelected(d.index)) {
            rowStyles.add('chart-legend-selected');
          }
        }
        rowStyles
            .addAll(d.series.map((ChartSeries x) => 'type-${x.renderer.name}'));

        color.style.setProperty('background-color', d.color);
        row.append(color);
        label.text = d.label;
        row.append(label);

        if (showValues) {
          value.text = d.value;
          value.style.setProperty('color', d.color);
          row.append(value);
        }
      }
      row.classes.addAll(rowStyles);
      return row;
    });

    // We have elements in the DOM that need updating.
    if (!isFirstRender) {
      rows.each((ChartLegendItem d, i, Element e) {
        var classes = e.classes;
        if (state != null) {
          if (d.index == state.preview) {
            classes.add('chart-legend-hover');
          } else {
            classes.remove('chart-legend-hover');
          }
          if (state.isSelected(d.index)) {
            classes.add('chart-legend-selected');
          } else {
            classes.remove('chart-legend-selected');
          }
        }
        classes.addAll(d.series.map((x) => 'type-${x.renderer.name}'));

        (e.children[0]).style.setProperty('background-color', d.color);
        (e.children[1]).text = d.label;
        if (showValues) {
          (e.lastChild as Element)
            ..text = d.value
            ..style.setProperty('color', d.color);
        }
      });
    }

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
  void _handleStateChanges(List<ChangeRecord> _) => _createLegendItems();
}
