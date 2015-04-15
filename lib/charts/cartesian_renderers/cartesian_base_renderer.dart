/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

abstract class CartesianRendererBase implements CartesianRenderer {
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  CartesianArea area;
  ChartSeries series;
  ChartTheme theme;
  ChartState state;
  Rect rect;
  List colorForKeyCache;

  Element host;
  Selection root;
  SelectionScope scope;

  StreamController<ChartEvent> mouseOverController;
  StreamController<ChartEvent> mouseOutController;
  StreamController<ChartEvent> mouseClickController;

  void _ensureAreaAndSeries(CartesianArea area, ChartSeries series) {
    assert(area != null && series != null);
    assert(this.area == null || this.area == area);
    if (this.area == null) {
      if (area.state != null) {
        this.state = area.state;
        _disposer.add(this.state.changes.listen(handleStateChanges));
      }
    }
    this.area = area;
    this.series = series;
  }

  void _ensureReadyToDraw(Element element) {
    assert(series != null && area != null);
    assert(element != null && element is GElement);

    if (scope == null) {
      host = element;
      scope = new SelectionScope.element(element);
      root = scope.selectElements([host]);
    }

    theme = area.theme;
    rect = area.layout.renderArea;
    resetColorCache();
  }

  void resetColorCache() {
    var data = area.data,
        length = area.useRowColoring == true
            ? data.rows.length
            : data.columns.length;
    colorForKeyCache = new List(length);
  }

  /// Override this method to handle state changes.
  void handleStateChanges(List<ChangeRecord> changes) {
    resetColorCache();
    var itemStateChanged =
        changes.any((x) =>
            x is ChartSelectionChangeRecord ||
            x is ChartVisibilityChangeRecord ||
            x is ChartPreviewChangeRecord);

    if (itemStateChanged) {
      for (int i = 0; i < series.measures.length; ++i) {
        var column = series.measures.elementAt(i),
            selection = getSelectionForColumn(column),
            colorStylePair = colorForKey(measure:column);

        selection.each((d,i, Element e) {
          e.classes
            ..removeWhere((String x) => ChartState.CLASS_NAMES.contains(x))
            ..add(colorStylePair.last);
        });

        selection.transition()
          ..style('fill', colorStylePair.first)
          ..style('stroke', colorStylePair.first)
          ..duration(50);
      }
    }
  }

  Selection getSelectionForColumn(int column);

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.row-group').remove();
  }

  @override
  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
    max = rows.isEmpty ? 0 : rows[0][series.measures.first],
    min = max;

    rows.forEach((row) {
      series.measures.forEach((idx) {
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }

  @override
  Stream<ChartEvent> get onValueMouseOver {
    if (mouseOverController == null) {
      mouseOverController = new StreamController.broadcast(sync: true);
    }
    return mouseOverController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseOut {
    if (mouseOutController == null) {
      mouseOutController = new StreamController.broadcast(sync: true);
    }
    return mouseOutController.stream;
  }

  @override
  Stream<ChartEvent> get onValueClick {
    if (mouseClickController == null) {
      mouseClickController = new StreamController.broadcast(sync: true);
    }
    return mouseClickController.stream;
  }

  double get bandInnerPadding => 1.0;
  double get bandOuterPadding =>
      area.theme.dimensionAxisTheme.axisOuterPadding;

  /// Get color and class names for use with each item in the chart. Both are
  /// based on the current state of the item.
  Pair<String,String> colorForKey({int index, int measure}) {
    int column = measure == null ? series.measures.elementAt(index) : measure;
    if (colorForKeyCache[column] == null) {
      int itemState = ChartTheme.STATE_NORMAL;
      List<String> classes = [];

      if (!state.selection.isEmpty) {
        if (state.selection.contains(column)) {
          classes.add(ChartState.SELECTED_CLASS);
        } else {
          classes.add(ChartState.UNSELECTED_CLASS);
          itemState = ChartTheme.STATE_DISABLED;
        }
      }
      if (state.hidden.contains(column)) {
        classes.add(ChartState.HIDDEN_CLASS);
      }
      if (state.preview == column) {
        classes.add(ChartState.PREVIEW_CLASS);
      }
      if (state.preview == column && state.selection.isEmpty) {
        itemState = ChartTheme.STATE_ACTIVE;
      }

      colorForKeyCache[column] =
          new Pair(theme.getColorForKey(column, itemState),
              classes.join(' '));
    }
    return colorForKeyCache[column];
  }
}