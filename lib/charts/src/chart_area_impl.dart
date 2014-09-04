part of charted.charts;

/**
 * Generic implementation of ChartArea.
 *
 * Assumes that the chart displays either one or two dimension axes and zero
 * or more measure axis.  The number of measure axes displayed is zero in charts
 * similar to bubble chart - the number of dimension axes is two.
 *
 * The primary dimension axes is always at the bottom, the primary measure axis
 * is always on the right.
 */
class _ChartArea implements ChartArea {
  static const List MEASURE_AXIS_IDS = const['_default'];
  static const List DIMENSION_AXIS_IDS = const['_primary', '_secondary'];

  static const List MEASURE_AXIS_ORIENTATIONS =
      const[ORIENTATION_LEFT, ORIENTATION_RIGHT];
  static const List MEASURE_AXIS_ORIENTATIONS_ALT =
      const[ORIENTATION_BOTTOM, ORIENTATION_TOP];

  static const List DIMENSION_AXIS_ORIENTATIONS =
      const[ORIENTATION_BOTTOM, ORIENTATION_LEFT];
  static const List DIMENSION_AXIS_ORIENTATIONS_ALT =
      const[ORIENTATION_LEFT, ORIENTATION_BOTTOM];

  static const int MEASURE_AXES_COUNT = 2;
  static const int MARGIN = 10;

  final LinkedHashMap<String, _ChartAxis> _measureAxes = new LinkedHashMap();
  final LinkedHashMap<int, _ChartAxis> _dimensionAxes = new LinkedHashMap();
  final HashSet<int> dimensionsUsingBands = new HashSet();
  final SubscriptionsDisposer _dataSubscriptions = new SubscriptionsDisposer();
  final SubscriptionsDisposer _configSubscriptions =
      new SubscriptionsDisposer();

  final Element host;

  ChartTheme theme;
  bool autoUpdate = false;

  ChartData _data;
  ChartConfig _config;
  int _dimensionAxesCount;

  _ChartAreaLayout layout = new _ChartAreaLayout();
  SelectionScope _scope;
  Selection _svg;
  Selection _group;
  Iterable<ChartSeries> _series;
  bool _pendingLegendUpdate = false;

  _ChartArea(Element this.host, ChartData data, ChartConfig config,
      bool this.autoUpdate, this._dimensionAxesCount) {
    assert(host != null);
    assert(isNotInline(host));

    this.data = data;
    this.config = config;
    theme = ChartTheme.current;


    Transition.defaultEasingType = theme.transitionEasingType;
    Transition.defaultEasingMode = theme.transitionEasingMode;
    Transition.defaultDuration = theme.transitionDuration;
  }

  static bool isNotInline(Element e) =>
      e != null && e.getComputedStyle().display != 'inline';

  /*
   * If [value] is [Observable], subscribes to changes and updates the
   * chart when data changes.
   */
  set data(ChartData value) {
    _data = value;
    _dataSubscriptions.dispose();

    if (autoUpdate && _data != null && _data is Observable) {
      _dataSubscriptions.add(
          (_data as Observable).changes.listen((_) => draw()));
    }
  }

  ChartData get data => _data;

  /*
   * If [value] is [Observable], subscribes to changes and updates the
   * chart when series or dimensions change in configuration.
   */
  set config(ChartConfig value) {
    _config = value;
    _configSubscriptions.dispose();
    _pendingLegendUpdate = true;

    if (_config != null)
      _configSubscriptions.add(
          (_config as Observable).changes.listen((_) {
      _pendingLegendUpdate = true;
      draw();
    }));
  }

  ChartConfig get config => _config;

  /*
   * Number of dimension axes displayed in this chart.
   */
  set dimensionAxesCount(int count) {
    _dimensionAxesCount = count;
    if (autoUpdate) draw();
  }

  int get dimensionAxesCount => _dimensionAxesCount;

  /*
   * Gets measure axis from cache - creates a new instance of _ChartAxis
   * if one was not already created for the given axis [id].
   */
  _ChartAxis _getMeasureAxis(String id) {
    _measureAxes.putIfAbsent(id, () {
      var axisConf = config.getMeasureAxis(id),
          axis = axisConf == null ?
              new _ChartAxis.withAxisConfig(this, axisConf) :
                  new _ChartAxis(this);
      return axis;
    });
    return _measureAxes[id];
  }

  /*
   * Gets a dimension axis from cache - creates a new instance of _ChartAxis
   * if one was not already created for the given dimension [column].
   */
  _ChartAxis _getDimensionAxis(int column) {
    _dimensionAxes.putIfAbsent(column, () {
      var axisConf = config.getDimensionAxis(column),
          axis = axisConf == null ?
              new _ChartAxis.withAxisConfig(this, axisConf) :
                  new _ChartAxis(this);
      return axis;
    });
    return _dimensionAxes[column];
  }

  /*
   * All columns rendered by a series must be of the same type and the
   * series must use a renderer that supports current [ChartArea]
   * configuration.
   */
  bool _isSeriesValid(ChartSeries s) {
    var first = data.columns.elementAt(s.measures.first).type;
    return s.measures.every((i) => data.columns.elementAt(i).type == first);
  }

  /*
   * Indicates if the given ChartSeries needs an ordinal scale
   */
  bool _isOrdinalColumn(column) =>
      column.useOrdinalScale == true ||
          (column.useOrdinalScale == null &&
              ChartColumnSpec.ORDINAL_SCALES.contains(column.type));

  /*
   * Get a list of dimension scales for this chart.
   */
  Iterable<Scale> get _dimensionScales =>
      config.dimensions.map((int column) => _getDimensionAxis(column).scale);

  /*
   * Get a list of scales used by [series]
   */
  Iterable<Scale> _measureScales(ChartSeries series) {
    var axisIds = isNullOrEmpty(series.measureAxisIds) ?
        MEASURE_AXIS_IDS : series.measureAxisIds;
    return axisIds.map((String id) => _getMeasureAxis(id).scale);
  }

  /*
   * Computes the size of chart and if changed from the previous time
   * size was computed, sets attributes on svg element
   */
  Rect _computeChartSize() {
    int width = host.clientWidth,
        height = host.clientHeight;

    if (config.minimumSize != null) {
      width = max([width, config.minimumSize.width]);
      height = max([height, config.minimumSize.height]);
    }

    Rect current = new Rect.size(width - 2 * MARGIN, height - 2 * MARGIN);
    if (layout.chartArea == null || layout.chartArea != current) {
      _svg.attr('width', width.toString());
      _svg.attr('height', height.toString());
      _group.attr('transform', 'translate($MARGIN, $MARGIN)');
      layout.chartArea = current;
    }
    return layout.chartArea;
  }

  draw() {
    assert(data != null && config != null);
    assert(config.series != null && config.series.isNotEmpty);

    /* Create SVG element and other one-time initializations. */
    if (_scope == null) {
      _scope = new SelectionScope.element(host);
      _svg = _scope.append('svg:svg')..classed('charted-chart');
      _group = _svg.append('g')..classed('chart-wrapper');
    }

    /* Compute sizes and filter out unsupported series */
    var size = _computeChartSize(),
        series = config.series.where((s) =>
            _isSeriesValid(s) && s.renderer.prepare(this, s)),
        selection = _group.selectAll('.series-group').data(series),
        axesDomainCompleter = new Completer();

    /*
     * Wait till the axes are rendered before rendering series.
     * In an SVG, z-index is based on the order of nodes in the DOM.
     */
    axesDomainCompleter.future.then((_) {
      /* If a series was not rendered before, add an SVG group for it */
      selection.enter.append('svg:g').classed('series-group');

      /* For all series recompute axis ranges and update the rendering */
      var transform =
          'translate(${layout.renderArea.x},${layout.renderArea.y})';
      selection.each((ChartSeries s, _, Element group) {
        group.attributes['transform'] = transform;
        s.renderer.draw(group, _dimensionScales, _measureScales(s));
      });

      /* A series that was rendered earlier isn't there anymore, remove it */
      selection.exit.remove();
    });

    // Save the list of valid series for use with legend and axes.
    _series = series;

    // If we have atleast one dimension axis, render the axes.
    if (dimensionAxesCount != 0) {
      _initAxes();
    } else {
      _computeLayoutWithoutAxes();
    }

    // Render the chart, now that the axes layer is already in DOM.
    axesDomainCompleter.complete();

    // Updates the legend if required.
    _updateLegend();
  }

  _initAxes() {
    var measureAxisUsers = {};

    /* Create necessary measures axes */
    _series.forEach((ChartSeries s) {
      var ids = isNullOrEmpty(s.measureAxisIds) ?
          MEASURE_AXIS_IDS : s.measureAxisIds;
      ids.forEach((id) {
        var axis = _getMeasureAxis(id),
            users = measureAxisUsers[id];
        if (users == null) {
          measureAxisUsers[id] = [s];
        } else {
          users.add(s);
        }
      });
    });

    /* Configure measure axes */
    measureAxisUsers.forEach((id, listOfSeries) {
      var sampleCol = listOfSeries.first.measures.first,
          sampleColSpec = data.columns.elementAt(sampleCol),
          axis = _getMeasureAxis(id),
          domain;

      if (sampleColSpec.useOrdinalScale) {
        /* TODO(prsd): Ordinal measure scale */
      } else {
        var lowest = min(listOfSeries.map((s) => s.renderer.extent.min)),
            highest = max(listOfSeries.map((s) => s.renderer.extent.max));

        // Use default domain if lowest and highest are the same, right now
        // lowest is always 0, change to lowest when we make use of it.
        if (highest != 0) domain = [0, highest];
      }
      axis.initAxisDomain(sampleCol, false, domain);
    });

    /* Configure dimension axes */
    config.dimensions.take(dimensionAxesCount).forEach((int column) {
       var axis = _getDimensionAxis(column),
           sampleColumnSpec = data.columns.elementAt(column),
           values = data.rows.map((row) => row.elementAt(column)),
           domain;

       if (sampleColumnSpec.useOrdinalScale) {
         domain = values.toList();
       } else {
         var extent = new Extent.items(values);
         domain = [extent.min, extent.max];
       }
       axis.initAxisDomain(column, true, domain);
    });

    /* Build a list of dimension axes that use range bands */
    dimensionsUsingBands.clear();
    _series.forEach((ChartSeries s) =>
        dimensionsUsingBands.addAll(s.renderer.dimensionsUsingBand));

    /* List of measure and dimension axes that are displayed */
    var measureAxesCount = dimensionAxesCount == 1 ? MEASURE_AXES_COUNT : 0,
        displayedMeasureAxes = (config.displayedMeasureAxes == null ?
            _measureAxes.keys.take(measureAxesCount) :
                config.displayedMeasureAxes.take(measureAxesCount)).
                    toList(growable:false),
        displayedDimensionAxes =
            config.dimensions.take(dimensionAxesCount).toList(growable:false);

    /* Compute size of the dimension axes */
    if (config.renderDimensionAxes != false) {
      var dimensionAxisOrientations = config.leftAxisIsPrimary ?
          DIMENSION_AXIS_ORIENTATIONS_ALT : DIMENSION_AXIS_ORIENTATIONS;
      displayedDimensionAxes.asMap().forEach((int index, int column) {
        var axis = _dimensionAxes[column],
            orientation = dimensionAxisOrientations[index];
        axis.prepareToDraw(orientation, theme.dimensionAxisTheme);
        layout.axes[orientation] = axis.size;
      });
    }

    /* Compute size of the measure axes */
    if (displayedMeasureAxes.isNotEmpty) {
      var measureAxisOrientations = config.leftAxisIsPrimary ?
          MEASURE_AXIS_ORIENTATIONS_ALT : MEASURE_AXIS_ORIENTATIONS;
      displayedMeasureAxes.asMap().forEach((int index, String key) {
        var axis = _measureAxes[key],
            orientation = measureAxisOrientations[index];
        axis.prepareToDraw(orientation, theme.measureAxisTheme);
        layout.axes[orientation] = axis.size;
      });
    }

    _computeLayoutWithAxes();

    /* Initialize output range on the invisible measure axes */
    if (_measureAxes.length != displayedMeasureAxes.length) {
      _measureAxes.keys.forEach((String axisId) {
        if (displayedMeasureAxes.contains(axisId)) return;
        _getMeasureAxis(axisId).initAxisScale(
            [layout.renderArea.height, 0], theme.measureAxisTheme);
      });
    }

    /* Display measure axes if we need to */
    if (displayedMeasureAxes.isNotEmpty) {
      var axisGroups =
          _group.selectAll('.measure-group').data(displayedMeasureAxes);

      /* Update measure axis (add/remove/update) */
      axisGroups.enter.append('svg:g');
      axisGroups
          ..each((axisId, index, group) {
              _getMeasureAxis(axisId).draw(group);
              group.classes.clear();
              group.classes.addAll(['measure-group','measure-${index}']);
            });
      axisGroups.exit.remove();
    }

    if (config.renderDimensionAxes != false) {
      /* Display the dimension axes */
      var dimAxisGroups =
              _group.selectAll('.dim-group').data(displayedDimensionAxes);

      /* Update dimension axes (add new / remove old / update remaining) */
      dimAxisGroups.enter.append('svg:g');
      dimAxisGroups
          ..each((column, index, group) {
              _getDimensionAxis(column).draw(group);
              group.classes.clear();
              group.classes.addAll(['dim-group', 'dim-${index}']);
            });
      dimAxisGroups.exit.remove();
    } else {
      /* Initialize output range on the invisible axis */
      var dimensionAxisOrientations = config.leftAxisIsPrimary ?
          DIMENSION_AXIS_ORIENTATIONS_ALT : DIMENSION_AXIS_ORIENTATIONS;
      for (int i = 0; i < dimensionAxesCount; i++) {
        var column = config.dimensions.elementAt(i),
            axis = _dimensionAxes[column],
            orientation = dimensionAxisOrientations[i];
        axis.initAxisScale(orientation == ORIENTATION_LEFT ?
            [layout.renderArea.height, 0] : [0, layout.renderArea.width],
            theme.dimensionAxisTheme);
      };
    }
  }

  _computeLayoutWithoutAxes() {
    layout.renderArea =
        new Rect(0, 0, layout.chartArea.width, layout.chartArea.height);
  }

  /* Compute chart render area size and positions of all elements */
  _computeLayoutWithAxes() {
    var topAxis = layout.axes[ORIENTATION_TOP],
        leftAxis = layout.axes[ORIENTATION_LEFT],
        bottomAxis = layout.axes[ORIENTATION_BOTTOM],
        rightAxis = layout.axes[ORIENTATION_RIGHT],
        renderAreaHeight = layout.chartArea.height -
            (topAxis.height + layout.axes[ORIENTATION_BOTTOM].height),
        renderAreaWidth = layout.chartArea.width -
            (leftAxis.width + layout.axes[ORIENTATION_RIGHT].width);

    layout.renderArea = new Rect(
        leftAxis.width, topAxis.height, renderAreaWidth, renderAreaHeight);

    layout.axes[ORIENTATION_TOP] =
        new Rect(leftAxis.width, 0, renderAreaWidth, topAxis.height);
    layout.axes[ORIENTATION_RIGHT] =
        new Rect(leftAxis.width + renderAreaWidth, topAxis.y,
            rightAxis.width, renderAreaHeight);
    layout.axes[ORIENTATION_BOTTOM] =
        new Rect(leftAxis.width, topAxis.height + renderAreaHeight,
            renderAreaWidth, bottomAxis.height);
    layout.axes[ORIENTATION_LEFT] =
        new Rect(leftAxis.width, topAxis.height,
            leftAxis.width, renderAreaHeight);
  }

  /*
   * Updates the legend, if configuration changed since the last
   * time the legend was updated.
   */
  _updateLegend() {
    if (!_pendingLegendUpdate) return;
    if (_config == null || _config.legend == null || _series.isEmpty) return;

    List legend = [];
    List seriesByColumn =
        new List.generate(data.columns.length, (i) => new List());

    _series.forEach((s) =>
        s.measures.forEach((m) => seriesByColumn[m].add(s)));

    seriesByColumn.asMap().forEach((int i, List s) {
      if (s.length == 0) return;
      legend.add(new ChartLegendItem(
          column:i, label:data.columns.elementAt(i).label, series:s,
          color:theme.getColorForKey(i)));
    });

    _config.legend.update(legend, this);
    _pendingLegendUpdate = false;
  }
}

class _ChartAreaLayout implements ChartAreaLayout {
  final Map<String, Rect> axes = {
    ORIENTATION_LEFT: const Rect(),
    ORIENTATION_RIGHT: const Rect(),
    ORIENTATION_TOP: const Rect(),
    ORIENTATION_BOTTOM: const Rect()
  };
  Rect renderArea;
  Rect chartArea;
}
