//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// Creates an empty area and provides generic API for interaction with layout
/// based charts.
class DefaultLayoutAreaImpl implements LayoutArea {
  /// Disposer for all change stream subscriptions related to data.
  final _dataEventsDisposer = new SubscriptionsDisposer();

  /// Disposer for all change stream subscriptions related to config.
  final _configEventsDisposer = new SubscriptionsDisposer();

  @override
  final Element host;

  @override
  final bool useRowColoring = true;

  @override
  final ChartState state;

  @override
  _ChartAreaLayout layout = new _ChartAreaLayout();

  @override
  Selection upperBehaviorPane;

  @override
  Selection lowerBehaviorPane;

  @override
  bool isReady = false;

  @override
  ChartTheme theme;

  ChartData _data;
  ChartConfig _config;
  bool _autoUpdate = false;

  SelectionScope _scope;
  Selection _svg;
  Selection visualization;

  ChartSeries _series;
  LayoutRenderer _renderer;

  bool _pendingLegendUpdate = false;
  List<ChartBehavior> _behaviors = new List<ChartBehavior>();

  SubscriptionsDisposer _rendererDisposer = new SubscriptionsDisposer();
  StreamController<ChartEvent> _valueMouseOverController;
  StreamController<ChartEvent> _valueMouseOutController;
  StreamController<ChartEvent> _valueMouseClickController;

  DefaultLayoutAreaImpl(this.host, ChartData data, ChartConfig config,
      this._autoUpdate, this.state) {
    assert(host != null);
    assert(isNotInline(host));

    this.data = data;
    this.config = config;
    theme = new QuantumChartTheme();

    Transition.defaultEasingType = theme.transitionEasingType;
    Transition.defaultEasingMode = theme.transitionEasingMode;
    Transition.defaultDurationMilliseconds =
        theme.transitionDurationMilliseconds;
  }

  void dispose() {
    _configEventsDisposer.dispose();
    _dataEventsDisposer.dispose();
    _config.legend?.dispose();
  }

  static bool isNotInline(Element e) =>
      e != null && e.getComputedStyle().display != 'inline';

  /// Set new data for this chart. If [value] is [Observable], subscribes to
  /// changes and updates the chart when data changes.
  @override
  set data(ChartData value) {
    _data = value;
    _dataEventsDisposer.dispose();

    if (autoUpdate && _data != null && _data is Observable) {
      _dataEventsDisposer.add((_data as Observable).changes.listen((_) {
        draw();
      }));
    }
  }

  @override
  ChartData get data => _data;

  /// Set new config for this chart. If [value] is [Observable], subscribes to
  /// changes and updates the chart when series or dimensions change.
  @override
  set config(ChartConfig value) {
    _config = value;
    _configEventsDisposer.dispose();
    _pendingLegendUpdate = true;

    if (_config != null && _config is Observable) {
      _configEventsDisposer.add((_config as Observable).changes.listen((_) {
        _pendingLegendUpdate = true;
        draw();
      }));
    }
  }

  @override
  ChartConfig get config => _config;

  @override
  set autoUpdate(bool value) {
    if (_autoUpdate != value) {
      _autoUpdate = value;
      this.data = _data;
      this.config = _config;
    }
  }

  @override
  bool get autoUpdate => _autoUpdate;

  /// Computes the size of chart and if changed from the previous time
  /// size was computed, sets attributes on svg element
  Rect _computeChartSize() {
    int width = host.clientWidth, height = host.clientHeight;

    if (config.minimumSize != null) {
      width = max([width, config.minimumSize.width]);
      height = max([height, config.minimumSize.height]);
    }

    AbsoluteRect padding = theme.padding;
    num paddingLeft = config.isRTL ? padding.end : padding.start;
    Rect current = new Rect(
        paddingLeft,
        padding.top,
        width - (padding.start + padding.end),
        height - (padding.top + padding.bottom));
    if (layout.chartArea == null || layout.chartArea != current) {
      var transform = 'translate(${paddingLeft},${padding.top})';

      visualization.first.attributes['transform'] = transform;
      lowerBehaviorPane.first.attributes['transform'] = transform;
      upperBehaviorPane.first.attributes['transform'] = transform;

      _svg.attr('width', width.toString());
      _svg.attr('height', height.toString());
      layout.chartArea = current;
      layout.renderArea = current;
      layout._axes.clear();
    }

    return layout.chartArea;
  }

  @override
  draw({bool preRender: false, Future schedulePostRender}) {
    assert(data != null && config != null);
    assert(config.series != null && config.series.isNotEmpty);

    // One time initialization.
    // Each [ChartArea] has it's own [SelectionScope]
    if (_scope == null) {
      _scope = new SelectionScope.element(host);
      _svg = _scope.append('svg:svg')..classed('chart-canvas');

      lowerBehaviorPane = _svg.append('g')..classed('lower-render-pane');
      visualization = _svg.append('g')..classed('chart-render-pane');
      upperBehaviorPane = _svg.append('g')..classed('upper-render-pane');

      if (_behaviors.isNotEmpty) {
        _behaviors
            .forEach((b) => b.init(this, upperBehaviorPane, lowerBehaviorPane));
      }
    }

    // Compute chart sizes and filter out unsupported series
    _computeChartSize();
    var series = config.series
            .firstWhere((s) => s.renderer.prepare(this, s), orElse: () => null),
        group = visualization.first.querySelector('.series-group');

    // We need atleast one matching series.
    assert(series != null);

    // Create a group for rendering, if it was not already done.
    if (group == null) {
      group = Namespace.createChildElement('g', visualization.first)
        ..classes.add('series-group');
      visualization.first.append(group);
    }

    // If we previously displayed a series, verify that we are
    // still using the same renderer.  Otherwise, dispose the older one.
    if (_renderer != series.renderer) {
      if (_renderer != null) _rendererDisposer.dispose();

      // Save and subscribe to events on the the current renderer.
      _renderer = series.renderer;
      if (_renderer is ChartRendererBehaviorSource) {
        _rendererDisposer.addAll([
          _renderer.onValueClick.listen((ChartEvent e) {
            if (state != null) {
              if (state.isSelected(e.row)) {
                state.unselect(e.row);
              } else {
                state.select(e.row);
              }
            }
            if (_valueMouseClickController != null) {
              _valueMouseClickController.add(e);
            }
          }),
          _renderer.onValueMouseOver.listen((ChartEvent e) {
            if (state != null) {
              state.preview = e.row;
            }
            if (_valueMouseOverController != null) {
              _valueMouseOverController.add(e);
            }
          }),
          _renderer.onValueMouseOut.listen((ChartEvent e) {
            if (state != null) {
              if (e.row == state.preview) {
                state.hovered = null;
              }
            }
            if (_valueMouseOutController != null) {
              _valueMouseOutController.add(e);
            }
          })
        ]);
      }
    }

    Iterable<ChartLegendItem> legend =
        _renderer.layout(group, schedulePostRender: schedulePostRender);

    // Notify on the stream that the chart has been updated.
    isReady = true;

    // Save the list of valid series and initialize axes.
    _series = series;

    // Updates the legend if required.
    if (_config.legend != null) {
      _config.legend.update(legend, this);
    }
  }

  @override
  Stream<ChartEvent> get onMouseUp =>
      host.onMouseUp.map((MouseEvent e) => new DefaultChartEventImpl(e, this));

  @override
  Stream<ChartEvent> get onMouseDown => host.onMouseDown
      .map((MouseEvent e) => new DefaultChartEventImpl(e, this));

  @override
  Stream<ChartEvent> get onMouseOver => host.onMouseOver
      .map((MouseEvent e) => new DefaultChartEventImpl(e, this));

  @override
  Stream<ChartEvent> get onMouseOut =>
      host.onMouseOut.map((MouseEvent e) => new DefaultChartEventImpl(e, this));

  @override
  Stream<ChartEvent> get onMouseMove => host.onMouseMove
      .map((MouseEvent e) => new DefaultChartEventImpl(e, this));

  @override
  Stream<ChartEvent> get onValueClick {
    if (_valueMouseClickController == null) {
      _valueMouseClickController = new StreamController.broadcast(sync: true);
    }
    return _valueMouseClickController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseOver {
    if (_valueMouseOverController == null) {
      _valueMouseOverController = new StreamController.broadcast(sync: true);
    }
    return _valueMouseOverController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseOut {
    if (_valueMouseOutController == null) {
      _valueMouseOutController = new StreamController.broadcast(sync: true);
    }
    return _valueMouseOutController.stream;
  }

  @override
  void addChartBehavior(ChartBehavior behavior) {
    if (behavior == null || _behaviors.contains(behavior)) return;
    _behaviors.add(behavior);
    if (upperBehaviorPane != null && lowerBehaviorPane != null) {
      behavior.init(this, upperBehaviorPane, lowerBehaviorPane);
    }
  }

  @override
  void removeChartBehavior(ChartBehavior behavior) {
    if (behavior == null || !_behaviors.contains(behavior)) return;
    if (upperBehaviorPane != null && lowerBehaviorPane != null) {
      behavior.dispose();
    }
    _behaviors.remove(behavior);
  }
}
