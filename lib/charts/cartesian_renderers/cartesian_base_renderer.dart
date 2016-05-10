//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

abstract class CartesianRendererBase implements CartesianRenderer {
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  CartesianArea area;
  ChartSeries series;
  ChartTheme theme;
  ChartState state;
  Rect rect;

  List<int> _columnStateCache;
  List<Iterable<String>> _columnStylesCache;

  final _valueColorCache = new Map<int, String>();
  final _valueFilterCache = new Map<int, String>();
  final _valueStylesCache = new Map<int, Iterable<String>>();

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
        _disposer.add(this.state.changes.listen((changes) {
          resetStylesCache();
          handleStateChanges(changes);
        }));
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
    resetStylesCache();
  }

  void resetStylesCache() {
    var length = area.data.columns.length;
    _columnStylesCache = new List(length);
    _columnStateCache = new List(length);
    _valueStylesCache.clear();
    _valueColorCache.clear();
    _valueFilterCache.clear();
    _computeColumnStates();
  }

  /// Override this method to handle state changes.
  void handleStateChanges(List<ChangeRecord> changes);

  @override
  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
        measures = series.measures,
        max = SMALL_INT_MIN,
        min = SMALL_INT_MAX;

    for (int i = 0, len = rows.length; i < len; ++i) {
      var row = rows.elementAt(i);
      for (int j = 0, jLen = measures.length; j < jLen; ++j) {
        var value = row.elementAt(measures.elementAt(j));
        if (value != null && value.isFinite) {
          if (value > max) {
            max = value;
          } else if (value < min) {
            min = value;
          }
        }
      }
    }
    return new Extent(min, max);
  }

  @override
  Extent extentForRow(Iterable row) {
    assert(series != null && area != null);
    var measures = series.measures, max = SMALL_INT_MIN, min = SMALL_INT_MAX;

    for (int i = 0, len = measures.length; i < len; ++i) {
      var measure = measures.elementAt(i), value = row.elementAt(measure);
      if (value != null && value.isFinite) {
        if (value > max) {
          max = value;
        } else if (value < min) {
          min = value;
        }
      }
    }
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
      area.theme.getDimensionAxisTheme().axisOuterPadding;

  void _computeColumnStates() {
    area.config.series.forEach((ChartSeries series) {
      series.measures.forEach((int column) {
        if (_columnStateCache[column] != null) return;
        int flags = 0;
        if (state != null && area.useRowColoring == false) {
          if (state.highlights.isNotEmpty) {
            flags |= (state.highlights.any((x) => x.first == column)
                ? ChartState.COL_HIGHLIGHTED
                : ChartState.COL_UNHIGHLIGHTED);
          }
          if (state.selection.isNotEmpty) {
            flags |= (state.isSelected(column)
                ? ChartState.COL_SELECTED
                : ChartState.COL_UNSELECTED);
          }
          if (!state.isVisible(column)) {
            flags |= ChartState.COL_HIDDEN;
          }
          if (state.preview == column) {
            flags |= ChartState.COL_PREVIEW;
          }
          if (state.hovered != null && state.hovered.first == column) {
            flags |= ChartState.COL_HOVERED;
          }
        }
        _columnStateCache[column] = flags;
      });
    });
  }

  Iterable<String> stylesForColumn(int column) {
    if (_columnStylesCache[column] == null) {
      if (state == null || area.useRowColoring) {
        _columnStylesCache[column] = const [];
      } else {
        var styles = <String>[], flags = _columnStateCache[column];

        if (flags & ChartState.COL_SELECTED != 0) {
          styles.add(ChartState.COL_SELECTED_CLASS);
        } else if (flags & ChartState.COL_UNSELECTED != 0) {
          styles.add(ChartState.COL_UNSELECTED_CLASS);
        }

        if (flags & ChartState.COL_HIGHLIGHTED != 0) {
          styles.add(ChartState.COL_HIGHLIGHTED_CLASS);
        } else if (flags & ChartState.COL_UNHIGHLIGHTED != 0) {
          styles.add(ChartState.COL_UNHIGHLIGHTED_CLASS);
        }

        if (flags & ChartState.COL_HOVERED != 0) {
          styles.add(ChartState.COL_HOVERED_CLASS);
        }
        if (flags & ChartState.COL_PREVIEW != 0) {
          styles.add(ChartState.COL_PREVIEW_CLASS);
        }
        if (flags & ChartState.COL_HIDDEN != 0) {
          styles.add(ChartState.COL_HIDDEN_CLASS);
        }

        _columnStylesCache[column] = styles;
      }
    }
    return _columnStylesCache[column];
  }

  String colorForColumn(int column) =>
      theme.getColorForKey(column, _columnStateCache[column]);

  String filterForColumn(int column) =>
      theme.getFilterForState(_columnStateCache[column]);

  Iterable<String> stylesForValue(int column, int row) {
    var hash = hash2(column, row);
    if (_valueStylesCache[hash] == null) {
      if (state == null) {
        _valueStylesCache[hash] = const [];
      } else {
        var styles = stylesForColumn(column).toList();
        if (state.highlights.isNotEmpty) {
          styles.add(state.highlights.any((x) => x.last == row)
              ? ChartState.VAL_HIGHLIGHTED_CLASS
              : ChartState.VAL_UNHIGHLIGHTED_CLASS);
        }
        if (state.hovered != null && state.hovered.last == row) {
          styles.add(ChartState.VAL_HOVERED_CLASS);
        }
        _valueStylesCache[hash] = styles;
      }
    }
    return _valueStylesCache[hash];
  }

  String colorForValue(int column, int row) {
    var hash = hash2(column, row);
    if (_valueColorCache[hash] == null) {
      _cacheColorsAndFilter(hash, column, row);
    }
    return _valueColorCache[hash];
  }

  String filterForValue(int column, int row) {
    var hash = hash2(column, row);
    if (_valueFilterCache[hash] == null) {
      _cacheColorsAndFilter(hash, column, row);
    }
    return _valueFilterCache[hash];
  }

  _cacheColorsAndFilter(int hash, int column, int row) {
    if (state == null) {
      _valueColorCache[hash] =
          theme.getColorForKey(area.useRowColoring ? row : column);
      _valueFilterCache[hash] = theme.getFilterForState(0);
    } else {
      var flags = _columnStateCache[column];
      if (state.highlights.isNotEmpty) {
        flags |= (state.highlights.any((x) => x.last == row)
            ? ChartState.VAL_HIGHLIGHTED
            : ChartState.VAL_UNHIGHLIGHTED);
      }
      if (state.hovered != null && state.hovered.last == row) {
        flags |= ChartState.VAL_HOVERED;
      }
      _valueColorCache[hash] =
          theme.getColorForKey(area.useRowColoring ? row : column, flags);
      _valueFilterCache[hash] = theme.getFilterForState(flags);
    }
  }
}
