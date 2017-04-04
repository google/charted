//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// Displays either one or two dimension axes and zero or more measure axis.
/// The number of measure axes displayed is zero in charts like bubble chart
/// which contain two dimension axes.
class DefaultCartesianAreaImpl implements CartesianArea {
  /// Default identifiers used by the measure axes
  static const MEASURE_AXIS_IDS = const <String>['_default'];

  /// Orientations used by measure axes. First, when "x" axis is the primary
  /// and the only dimension. Second, when "y" axis is the primary and the only
  /// dimension.
  static const MEASURE_AXIS_ORIENTATIONS = const [
    const [ORIENTATION_LEFT, ORIENTATION_RIGHT],
    const [ORIENTATION_BOTTOM, ORIENTATION_TOP]
  ];

  /// Orientations used by the dimension axes. First, when "x" is the
  /// primary dimension and the last one for cases where "y" axis is primary
  /// dimension.
  static const DIMENSION_AXIS_ORIENTATIONS = const [
    const [ORIENTATION_BOTTOM, ORIENTATION_LEFT],
    const [ORIENTATION_LEFT, ORIENTATION_BOTTOM]
  ];

  /// Mapping of measure axis Id to it's axis.
  final _measureAxes = new LinkedHashMap<String, DefaultChartAxisImpl>();

  /// Mapping of dimension column index to it's axis.
  final _dimensionAxes = new LinkedHashMap<int, DefaultChartAxisImpl>();

  /// Disposer for all change stream subscriptions related to data.
  final _dataEventsDisposer = new SubscriptionsDisposer();

  /// Disposer for all change stream subscriptions related to config.
  final _configEventsDisposer = new SubscriptionsDisposer();

  @override
  final Element host;

  @override
  final bool useTwoDimensionAxes;

  @override
  final bool useRowColoring;

  /// Indicates whether any renderers need bands on primary dimension
  final List<int> dimensionsUsingBands = [];

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

  Iterable<ChartSeries> _series;

  bool _pendingLegendUpdate = false;
  bool _pendingAxisConfigUpdate = false;
  List<ChartBehavior> _behaviors = new List<ChartBehavior>();
  Map<ChartSeries, _ChartSeriesInfo> _seriesInfoCache = new Map();

  StreamController<ChartEvent> _valueMouseOverController;
  StreamController<ChartEvent> _valueMouseOutController;
  StreamController<ChartEvent> _valueMouseClickController;
  StreamController<ChartArea> _chartAxesUpdatedController;

  DefaultCartesianAreaImpl(
      this.host,
      ChartData data,
      ChartConfig config,
      bool autoUpdate,
      this.useTwoDimensionAxes,
      this.useRowColoring,
      this.state)
      : _autoUpdate = autoUpdate {
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
    _config?.legend?.dispose();

    if (_valueMouseOverController != null) {
      _valueMouseOverController.close();
      _valueMouseOverController = null;
    }
    if (_valueMouseOutController != null) {
      _valueMouseOutController.close();
      _valueMouseOutController = null;
    }
    if (_valueMouseClickController != null) {
      _valueMouseClickController.close();
      _valueMouseClickController = null;
    }
    if (_chartAxesUpdatedController != null) {
      _chartAxesUpdatedController.close();
      _chartAxesUpdatedController = null;
    }
    if (_behaviors.isNotEmpty) {
      _behaviors.forEach((behavior) => behavior.dispose());
    }
  }

  static bool isNotInline(Element e) =>
      e != null && e.getComputedStyle().display != 'inline';

  /// Set new data for this chart. If [value] is [Observable], subscribes to
  /// changes and updates the chart when data changes.
  @override
  set data(ChartData value) {
    _data = value;
    _dataEventsDisposer.dispose();
    _pendingLegendUpdate = true;

    if (autoUpdate && _data != null && _data is Observable) {
      _dataEventsDisposer.add((_data as Observable).changes.listen((_) {
        _pendingLegendUpdate = true;
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
    _pendingAxisConfigUpdate = true;

    if (_config != null && _config is Observable) {
      _configEventsDisposer.add((_config as Observable).changes.listen((_) {
        _pendingAxisConfigUpdate = true;
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

  /// Gets measure axis from cache - creates a new instance of _ChartAxis
  /// if one was not already created for the given [axisId].
  DefaultChartAxisImpl _getMeasureAxis(String axisId) {
    _measureAxes.putIfAbsent(axisId, () {
      var axisConf = config.getMeasureAxis(axisId),
          axis = axisConf != null
              ? new DefaultChartAxisImpl.withAxisConfig(this, axisConf)
              : new DefaultChartAxisImpl(this);
      return axis;
    });

    return _measureAxes[axisId];
  }

  /// Gets a dimension axis from cache - creates a new instance of _ChartAxis
  /// if one was not already created for the given dimension [column].
  DefaultChartAxisImpl _getDimensionAxis(int column) {
    _dimensionAxes.putIfAbsent(column, () {
      var axisConf = config.getDimensionAxis(column),
          axis = axisConf != null
              ? new DefaultChartAxisImpl.withAxisConfig(this, axisConf)
              : new DefaultChartAxisImpl(this);
      return axis;
    });
    return _dimensionAxes[column];
  }

  /// All columns rendered by a series must be of the same type.
  bool _isSeriesValid(ChartSeries s) {
    var first = data.columns.elementAt(s.measures.first).type;
    return s.measures.every((i) =>
        (i < data.columns.length) && data.columns.elementAt(i).type == first);
  }

  @override
  Iterable<Scale> get dimensionScales =>
      config.dimensions.map((int column) => _getDimensionAxis(column).scale);

  @override
  Iterable<Scale> measureScales(ChartSeries series) {
    var axisIds = isNullOrEmpty(series.measureAxisIds)
        ? MEASURE_AXIS_IDS
        : series.measureAxisIds;
    return axisIds.map((String id) => _getMeasureAxis(id).scale);
  }

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
      _svg.attr('width', width.toString());
      _svg.attr('height', height.toString());
      layout.chartArea = current;

      var transform = 'translate(${paddingLeft},${padding.top})';
      visualization.first.attributes['transform'] = transform;
      lowerBehaviorPane.first.attributes['transform'] = transform;
      upperBehaviorPane.first.attributes['transform'] = transform;
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
      if (!isNullOrEmpty(theme.filters)) {
        var element = _svg.first,
            defs = Namespace.createChildElement('defs', element)
              ..append(new SvgElement.svg(theme.filters,
                  treeSanitizer: new NullTreeSanitizer()));
        _svg.first.append(defs);
      }

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
            .where((s) => _isSeriesValid(s) && s.renderer.prepare(this, s)),
        selection = visualization
            .selectAll('.series-group')
            .data(series, (x) => x.hashCode),
        axesDomainCompleter = new Completer();

    // Wait till the axes are rendered before rendering series.
    // In an SVG, z-index is based on the order of nodes in the DOM.
    axesDomainCompleter.future.then((_) {
      selection.enter.append('svg:g')..classed('series-group');
      String transform =
          'translate(${layout.renderArea.x},${layout.renderArea.y})';

      selection.each((ChartSeries s, _, Element group) {
        _ChartSeriesInfo info = _seriesInfoCache[s];
        if (info == null) {
          info = _seriesInfoCache[s] = new _ChartSeriesInfo(this, s);
        }
        info.check();
        group.attributes['transform'] = transform;
        (s.renderer as CartesianRenderer)
            ?.draw(group, schedulePostRender: schedulePostRender);
      });

      // A series that was rendered earlier isn't there anymore, remove it
      selection.exit
        ..each((ChartSeries s, _, __) {
          var info = _seriesInfoCache.remove(s);
          if (info != null) {
            info.dispose();
          }
        })
        ..remove();

      // Notify on the stream that the chart has been updated.
      isReady = true;
      if (_chartAxesUpdatedController != null) {
        _chartAxesUpdatedController.add(this);
      }
    });

    // Save the list of valid series and initialize axes.
    _series = series;
    _updateAxisConfig();
    _initAxes(preRender: preRender);

    // Render the chart, now that the axes layer is already in DOM.
    axesDomainCompleter.complete();

    // Updates the legend if required.
    _updateLegend();
  }

  String _orientRTL(String orientation) => orientation;

  /// Initialize the axes - required even if the axes are not being displayed.
  _initAxes({bool preRender: false}) {
    Map measureAxisUsers = <String, Iterable<ChartSeries>>{};
    var keysToRemove = _measureAxes.keys.toList();

    // Create necessary measures axes.
    // If measure axes were not configured on the series, default is used.
    _series.forEach((ChartSeries s) {
      var measureAxisIds =
          isNullOrEmpty(s.measureAxisIds) ? MEASURE_AXIS_IDS : s.measureAxisIds;
      measureAxisIds.forEach((axisId) {
        if (keysToRemove.contains(axisId)) {
          keysToRemove.remove(axisId);
        }
        _getMeasureAxis(axisId); // Creates axis if required
        var users = measureAxisUsers[axisId];
        if (users == null) {
          measureAxisUsers[axisId] = [s];
        } else {
          users.add(s);
        }
      });
    });

    for (var key in keysToRemove) {
      _measureAxes.remove(key);
    }

    // Now that we know a list of series using each measure axis, configure
    // the input domain of each axis.
    measureAxisUsers.forEach((id, listOfSeries) {
      var sampleCol = listOfSeries.first.measures.first,
          sampleColSpec = data.columns.elementAt(sampleCol),
          axis = _getMeasureAxis(id);
      List domain;

      if (sampleColSpec.useOrdinalScale) {
        throw new UnsupportedError(
            'Ordinal measure axes are not currently supported.');
      } else {
        // Extent is available because [ChartRenderer.prepare] was already
        // called (when checking for valid series in [draw].
        Iterable extents = listOfSeries.map((s) => s.renderer.extent).toList();
        var lowest = min(extents.map((e) => e.min)),
            highest = max(extents.map((e) => e.max));

        // Use default domain if lowest and highest are the same, right now
        // lowest is always 0 unless it is less than 0 - change to lowest when
        // we make use of it.
        domain = highest == lowest
            ? (highest == 0
                ? [0, 1]
                : (highest < 0 ? [highest, 0] : [0, highest]))
            : (lowest <= 0 ? [lowest, highest] : [0, highest]);
      }
      axis.initAxisDomain(sampleCol, false, domain);
    });

    // Configure dimension axes.
    int dimensionAxesCount = useTwoDimensionAxes ? 2 : 1;
    config.dimensions.take(dimensionAxesCount).forEach((int column) {
      var axis = _getDimensionAxis(column),
          sampleColumnSpec = data.columns.elementAt(column),
          values = data.rows.map((row) => row.elementAt(column)),
          domain;

      if (sampleColumnSpec.useOrdinalScale) {
        domain = values.map((e) => e.toString()).toList();
      } else {
        var extent = new Extent.items(values);
        domain = [extent.min, extent.max];
      }
      axis.initAxisDomain(column, true, domain);
    });

    // See if any dimensions need "band" on the axis.
    dimensionsUsingBands.clear();
    List<bool> usingBands = [false, false];
    _series.forEach((ChartSeries s) =>
        (s.renderer as CartesianRenderer).dimensionsUsingBand.forEach((x) {
          if (x <= 1 && !(usingBands[x])) {
            usingBands[x] = true;
            dimensionsUsingBands.add(config.dimensions.elementAt(x));
          }
        }));

    // List of measure and dimension axes that are displayed
    assert(isNullOrEmpty(config.displayedMeasureAxes) ||
        config.displayedMeasureAxes.length < 2);
    var measureAxesCount = dimensionAxesCount == 1 ? 2 : 0,
        displayedMeasureAxes = (isNullOrEmpty(config.displayedMeasureAxes)
                ? _measureAxes.keys.take(measureAxesCount)
                : config.displayedMeasureAxes.take(measureAxesCount))
            .toList(growable: false),
        displayedDimensionAxes =
        config.dimensions.take(dimensionAxesCount).toList(growable: false);

    // Compute size of the dimension axes
    if (config.renderDimensionAxes != false) {
      var dimensionAxisOrientations = config.isLeftAxisPrimary
          ? DIMENSION_AXIS_ORIENTATIONS.last
          : DIMENSION_AXIS_ORIENTATIONS.first;
      for (int i = 0, len = displayedDimensionAxes.length; i < len; ++i) {
        var axis = _dimensionAxes[displayedDimensionAxes[i]],
            orientation = _orientRTL(dimensionAxisOrientations[i]);
        axis.prepareToDraw(orientation);
        layout._axes[orientation] = axis.size;
      }
    }

    // Compute size of the measure axes
    if (displayedMeasureAxes.isNotEmpty) {
      var measureAxisOrientations = config.isLeftAxisPrimary
          ? MEASURE_AXIS_ORIENTATIONS.last
          : MEASURE_AXIS_ORIENTATIONS.first;
      displayedMeasureAxes.asMap().forEach((int index, String key) {
        var axis = _measureAxes[key],
            orientation = _orientRTL(measureAxisOrientations[index]);
        axis.prepareToDraw(orientation);
        layout._axes[orientation] = axis.size;
      });
    }

    // Consolidate all the information that we collected into final layout
    _computeLayout(
        displayedMeasureAxes.isEmpty && config.renderDimensionAxes == false);

    // Domains for all axes have been taken care of and _ChartAxis ensures
    // that the scale is initialized on visible axes. Initialize the scale on
    // all invisible measure scales.
    if (_measureAxes.length != displayedMeasureAxes.length) {
      _measureAxes.keys.forEach((String axisId) {
        if (displayedMeasureAxes.contains(axisId)) return;
        _getMeasureAxis(axisId).initAxisScale([layout.renderArea.height, 0]);
      });
    }

    // Draw the visible measure axes, if any.
    if (displayedMeasureAxes.isNotEmpty) {
      var axisGroups = visualization
          .selectAll('.measure-axis-group')
          .data(displayedMeasureAxes);
      // Update measure axis (add/remove/update)
      axisGroups.enter.append('svg:g');
      axisGroups.each((axisId, index, group) {
        _getMeasureAxis(axisId).draw(group, _scope, preRender: preRender);
        group.attributes['class'] = 'measure-axis-group measure-${index}';
      });
      axisGroups.exit.remove();
    }

    // Draw the dimension axes, unless asked not to.
    if (config.renderDimensionAxes != false) {
      var dimAxisGroups = visualization
          .selectAll('.dimension-axis-group')
          .data(displayedDimensionAxes);
      // Update dimension axes (add/remove/update)
      dimAxisGroups.enter.append('svg:g');
      dimAxisGroups.each((column, index, group) {
        _getDimensionAxis(column).draw(group, _scope, preRender: preRender);
        group.attributes['class'] = 'dimension-axis-group dim-${index}';
      });
      dimAxisGroups.exit.remove();
    } else {
      // Initialize scale on invisible axis
      var dimensionAxisOrientations = config.isLeftAxisPrimary
          ? DIMENSION_AXIS_ORIENTATIONS.last
          : DIMENSION_AXIS_ORIENTATIONS.first;
      for (int i = 0; i < dimensionAxesCount; ++i) {
        var column = config.dimensions.elementAt(i),
            axis = _dimensionAxes[column],
            orientation = dimensionAxisOrientations[i];
        axis.initAxisScale(orientation == ORIENTATION_LEFT
            ? [layout.renderArea.height, 0]
            : [0, layout.renderArea.width]);
      }
      ;
    }
  }

  // Compute chart render area size and positions of all elements
  _computeLayout(bool notRenderingAxes) {
    if (notRenderingAxes) {
      layout.renderArea =
          new Rect(0, 0, layout.chartArea.height, layout.chartArea.width);
      return;
    }

    var top = layout.axes[ORIENTATION_TOP],
        left = layout.axes[ORIENTATION_LEFT],
        bottom = layout.axes[ORIENTATION_BOTTOM],
        right = layout.axes[ORIENTATION_RIGHT];

    var renderAreaHeight = layout.chartArea.height -
            (top.height + layout.axes[ORIENTATION_BOTTOM].height),
        renderAreaWidth = layout.chartArea.width -
            (left.width + layout.axes[ORIENTATION_RIGHT].width);

    layout.renderArea =
        new Rect(left.width, top.height, renderAreaWidth, renderAreaHeight);

    layout._axes
      ..[ORIENTATION_TOP] = new Rect(left.width, 0, renderAreaWidth, top.height)
      ..[ORIENTATION_RIGHT] = new Rect(
          left.width + renderAreaWidth, top.y, right.width, renderAreaHeight)
      ..[ORIENTATION_BOTTOM] = new Rect(left.width,
          top.height + renderAreaHeight, renderAreaWidth, bottom.height)
      ..[ORIENTATION_LEFT] =
          new Rect(left.width, top.height, left.width, renderAreaHeight);
  }

  // Updates the legend, if configuration changed since the last
  // time the legend was updated.
  _updateLegend() {
    if (!_pendingLegendUpdate) return;
    if (_config == null || _config.legend == null || _series.isEmpty) return;

    var legend = <ChartLegendItem>[];
    List<List<ChartSeries>> seriesByColumn =
        new List<List<ChartSeries>>.generate(
            data.columns.length, (_) => <ChartSeries>[]);

    _series.forEach((s) => s.measures.forEach((m) => seriesByColumn[m].add(s)));

    seriesByColumn.asMap().forEach((int i, List<ChartSeries> s) {
      if (s.length == 0) return;
      legend.add(new ChartLegendItem(
          index: i,
          label: data.columns.elementAt(i).label,
          series: s,
          color: theme.getColorForKey(i)));
    });

    _config.legend.update(legend, this);
    _pendingLegendUpdate = false;
  }

  // Updates the AxisConfig, if configuration chagned since the last time the
  // AxisConfig was updated.
  _updateAxisConfig() {
    if (!_pendingAxisConfigUpdate) return;
    _series.forEach((ChartSeries s) {
      var measureAxisIds =
          isNullOrEmpty(s.measureAxisIds) ? MEASURE_AXIS_IDS : s.measureAxisIds;
      measureAxisIds.forEach((axisId) {
        var axis = _getMeasureAxis(axisId); // Creates axis if required
        axis.config = config.getMeasureAxis(axisId);
      });
    });

    int dimensionAxesCount = useTwoDimensionAxes ? 2 : 1;
    config.dimensions.take(dimensionAxesCount).forEach((int column) {
      var axis = _getDimensionAxis(column);
      axis.config = config.getDimensionAxis(column);
    });

    _pendingAxisConfigUpdate = false;
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
  Stream<ChartArea> get onChartAxesUpdated {
    if (_chartAxesUpdatedController == null) {
      _chartAxesUpdatedController = new StreamController.broadcast(sync: true);
    }
    return _chartAxesUpdatedController.stream;
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

class _ChartAreaLayout implements ChartAreaLayout {
  final _axes = <String, Rect>{
    ORIENTATION_LEFT: const Rect(),
    ORIENTATION_RIGHT: const Rect(),
    ORIENTATION_TOP: const Rect(),
    ORIENTATION_BOTTOM: const Rect()
  };

  UnmodifiableMapView<String, Rect> _axesView;

  @override
  get axes => _axesView;

  @override
  Rect renderArea = const Rect();

  @override
  Rect chartArea = const Rect();

  _ChartAreaLayout() {
    _axesView = new UnmodifiableMapView(_axes);
  }
}

class _ChartSeriesInfo {
  CartesianRenderer _renderer;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  DefaultChartSeriesImpl _series;
  DefaultCartesianAreaImpl _area;
  _ChartSeriesInfo(this._area, this._series);

  _click(ChartEvent e) {
    var state = _area.state;
    if (state != null) {
      if (state.isHighlighted(e.column, e.row)) {
        state.unhighlight(e.column, e.row);
      } else {
        state.highlight(e.column, e.row);
      }
    }
    if (_area._valueMouseClickController != null) {
      _area._valueMouseClickController.add(e);
    }
  }

  _mouseOver(ChartEvent e) {
    var state = _area.state;
    if (state != null) {
      state.hovered = new Pair(e.column, e.row);
    }
    if (_area._valueMouseOverController != null) {
      _area._valueMouseOverController.add(e);
    }
  }

  _mouseOut(ChartEvent e) {
    var state = _area.state;
    if (state != null) {
      var current = state.hovered;
      if (current != null &&
          current.first == e.column &&
          current.last == e.row) {
        state.hovered = null;
      }
    }
    if (_area._valueMouseOutController != null) {
      _area._valueMouseOutController.add(e);
    }
  }

  check() {
    if (_renderer != _series.renderer) {
      dispose();
      if (_series.renderer is ChartRendererBehaviorSource) {
        _disposer.addAll([
          _series.renderer.onValueClick.listen(_click),
          _series.renderer.onValueMouseOver.listen(_mouseOver),
          _series.renderer.onValueMouseOut.listen(_mouseOut)
        ]);
      }
    }
    _renderer = _series.renderer;
  }

  dispose() {
    _renderer?.dispose();
    _disposer.dispose();
  }
}
