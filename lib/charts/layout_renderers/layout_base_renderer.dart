//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

abstract class LayoutRendererBase implements LayoutRenderer {
  static const MAX_SUPPORTED_ROWS = 250;
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  LayoutArea area;
  ChartSeries series;
  ChartTheme theme;
  ChartState state;
  Rect rect;

  List<int> _valueStateCache;
  List<Iterable<String>> _valueStylesCache;

  Element host;
  Selection root;
  SelectionScope scope;

  StreamController<ChartEvent> mouseOverController;
  StreamController<ChartEvent> mouseOutController;
  StreamController<ChartEvent> mouseClickController;

  void _ensureAreaAndSeries(ChartArea area, ChartSeries series) {
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
    var length = math.min(area.data.rows.length, MAX_SUPPORTED_ROWS);
    _valueStylesCache = new List(length);
    _valueStateCache = new List(length);
    _computeValueStates();
  }

  void handleStateChanges(List<ChangeRecord> changes);

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.row-group').remove();
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

  void _computeValueStates() {
    var length = math.min(area.data.rows.length, MAX_SUPPORTED_ROWS);
    for (int i = 0, len = length; i < len; ++i) {
      int flags = 0;
      if (state != null) {
        if (state.selection.isNotEmpty) {
          flags |= (state.isSelected(i))
              ? ChartState.VAL_HIGHLIGHTED
              : ChartState.VAL_UNHIGHLIGHTED;
        }
        if (state.preview == i) {
          flags |= ChartState.VAL_HOVERED;
        }
      }
      _valueStateCache[i] = flags;
    }
  }

  Iterable<String> stylesForValue(int row, {bool isTail: false}) {
    if (isTail == true) return const [];
    if (_valueStylesCache[row] == null) {
      if (state == null) {
        _valueStylesCache[row] = const [];
      } else {
        var styles = <String>[], flags = _valueStateCache[row];

        if (flags & ChartState.VAL_HIGHLIGHTED != 0) {
          styles.add(ChartState.VAL_HIGHLIGHTED_CLASS);
        } else if (flags & ChartState.VAL_UNHIGHLIGHTED != 0) {
          styles.add(ChartState.VAL_UNHIGHLIGHTED_CLASS);
        }
        if (flags & ChartState.VAL_HOVERED != 0) {
          styles.add(ChartState.VAL_HOVERED_CLASS);
        }

        _valueStylesCache[row] = styles;
      }
    }
    return _valueStylesCache[row];
  }

  String colorForValue(int row, {bool isTail: false}) => isTail
      ? theme.getOtherColor()
      : theme.getColorForKey(row, _valueStateCache[row]);
}
