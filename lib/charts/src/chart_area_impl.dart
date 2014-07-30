/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
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
  static const int MEASURE_AXES_COUNT = 2;
  static const int MARGIN = 10;

  ChartData _data;
  ChartConfig _config;
  int _dimensionAxesCount;

  ChartTheme theme;
  bool autoUpdate = false;
  double innerPadding;
  double outerPadding;

  int xAxisWidth;
  int yAxisHeight;

  LinkedHashMap<String, ChartAxis> _measureAxes = new LinkedHashMap();
  LinkedHashMap<String, ChartAxis> _dimensionAxes = new LinkedHashMap();

  Map<String, List<ChartSeries>> _measureAxisUsers = new Map();

  SubscriptionsDisposer _dataSubscriptions = new SubscriptionsDisposer();
  SubscriptionsDisposer _configSubscriptions = new SubscriptionsDisposer();

  HashSet<int> dimensionsUsingBands = new HashSet();

  SelectionScope _scope;
  Selection _svg;
  Iterable<ChartSeries> _series;
  bool _pendingLegendUpdate = false;

  final Element host;

  _ChartArea(Element this.host, ChartData data, ChartConfig config,
      bool this.autoUpdate, int dimensionAxesCount) {
    assert(host != null);
    assert(isNotInline(host));

    this.data = data;
    this.config = config;
    _dimensionAxesCount = dimensionAxesCount;
    theme = ChartTheme.current;

    outerPadding = theme.outerPadding;
    innerPadding = 1.0;

    Transition.defaultEasingMode = theme.easingMode;
    Transition.defaultEasingType = theme.easingType;
    Transition.defaultDuration = theme.transitionDuration;
  }

  static bool isNotInline(Element e) =>
      e != null && e.getComputedStyle().display != 'inline';

  set data(ChartData value) {
    _data = value;
    _dataSubscriptions.dispose();

    if (autoUpdate && _data != null && _data is ChartDataObservable) {
      var observable = (_data as ChartDataObservable);
      _dataSubscriptions.add(observable.onValuesUpdated.listen((_) => draw()));
      _dataSubscriptions.add(observable.onRowsChanged.listen((_) => draw()));
    }
  }

  ChartData get data => _data;

  set config(ChartConfig value) {
    _config = value;
    _configSubscriptions.dispose();
    _pendingLegendUpdate = true;

    if (_config != null)
      _configSubscriptions.add(_config.changes.listen(_updateToConfig));
  }

  ChartConfig get config => _config;

  set dimensionAxesCount(int count) {
    _dimensionAxesCount = count;
    if (autoUpdate) {
      draw();
    }
  }

  int get dimensionAxesCount => _dimensionAxesCount;

  _updateToConfig(_) {
    _pendingLegendUpdate = true;
    draw();
  }

  _updateLegend() {
    bool hasPieSeries = _seriesWithCompatiblePieRenderer();
    if (!(_pendingLegendUpdate || hasPieSeries)) return;
    if (_config == null || _config.legend == null || _series.isEmpty) return;

    List legend = [];

    if (!hasPieSeries) {
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
    } else {
      for (int i = 0; i < _data.rows.length; i++) {
        legend.add(new ChartLegendItem(
            column:i, label: _data.rows.elementAt(i).elementAt(0),
            color:theme.getColorForKey(i)));
      }
    }

    _config.legend.update(legend, this);
    _pendingLegendUpdate = false;
  }

  ChartAxis getMeasureAxis(String id, {bool force: false}) {
    if (force) _measureAxes.putIfAbsent(id, () => new ChartAxis());
    return _measureAxes[id];
  }

  void setMeasureAxis(String id, ChartAxis axis) {
    assert(axis != null && !isBlank(id));
    _measureAxes[id] = axis;
  }

  ChartAxis getDimensionAxis(String id, {bool force: false}) {
    assert(!isBlank(id));
    if (force) _dimensionAxes.putIfAbsent(id, () => new ChartAxis());
    return _dimensionAxes[id];
  }

  void setDimensionAxis(String id, ChartAxis axis) {
    assert(!isBlank(id));
    assert(axis != null);
    _dimensionAxes[id] = axis;
  }

  /*
   * All columns rendered by a series must be of the same type and the
   * series must use a renderer that supports current [ChartArea]
   * configuration.
   */
  bool _isSeriesValid(ChartSeries s) {
    var first = data.columns.elementAt(s.measures.first).type;
    return s.measures.every((i) => data.columns.elementAt(i).type == first) &&
        s.renderer.isAreaCompatible(this);
  }

  /* Indicates if the given ChartSeries needs an ordinal scale */
  bool _isOrdinalColumn(column) {
    return column.useOrdinalScale == true || (column.useOrdinalScale == null &&
        ChartColumnSpec.ORDINAL_SCALES.contains(column.type));
  }

  /* Indicates if there is ChartSeries with compatible piechart renderer */
  bool _seriesWithCompatiblePieRenderer() {
    bool hasPieSeries = false;
    _series.forEach((ChartSeries s) {
      if (s.renderer is PieChartRenderer && s.renderer.isAreaCompatible(this)) {
        hasPieSeries = true;
      }
    });
    return hasPieSeries;
  }

  draw() {
    assert(data != null && config != null);
    assert(config.series != null && config.series.isNotEmpty);

    /* Create SVG element and other one-time initializations. */
    if (_scope == null) {
      _scope = new SelectionScope.element(host);
      _svg = _scope.append('svg:svg')..classed('charted-chart');
    }

    /*
     * Used to compute scales for the axis and to count the number of
     * actively used axes in this chart area.
     */
    _measureAxisUsers.clear();

    /* Compute sizes for axes and chart rendering area */
    var width = config.width != null ? config.width : host.clientWidth,
        height = config.height != null ? config.height : host.clientHeight,
        offsetX = 0,
        offsetY = 0;

    yAxisHeight = height - (2 * MARGIN);
    xAxisWidth = width - (2 * MARGIN);
    if (dimensionAxesCount > 0) yAxisHeight -= config.xAxisHeight;

    _svg.attr('width', width.toString());
    _svg.attr('height', height.toString());

    /* Filter out unsupported series */
    var series = config.series.where((s) => _isSeriesValid(s)),
        selection = _svg.selectAll('.series-group').data(series),
        axesDomainCompleter = new Completer();

    series.forEach((ChartSeries s) {
      var ids = isNullOrEmpty(s.measureAxisIds) ?
          ChartArea.MEASURE_AXIS_IDS : s.measureAxisIds;

      s.renderer.chart = this;
      s.renderer.series = s;

      ids.forEach((id) {
        var axis = getMeasureAxis(id, force: true),
            users = _measureAxisUsers[id];
        if (users == null) _measureAxisUsers[id] = [s]; else users.add(s);
      });
    });

    /*
     * Wait till the axes are rendered before rendering series.
     * In an SVG, z-index is based on the order of nodes in the DOM.
     */
    axesDomainCompleter.future.then((_) {
      /* If a series was not rendered before, add an SVG group for it */
      selection.enter.append('svg:g');

      /*
       * For all the existing series (those that existed and the new) recompute
       * axis ranges and update the rendering.
       * TODO(prsd): When ChartData is observable, get a list of series that got
       *     updated, so that only that series, and those that are effected by
       *     it are updated. Currently we are updating the entire chart.
       */
      selection.each((ChartSeries s, _, Element group) {
        /* Wait for the axes domain to be computed before rendering series */
        group.attributes.addAll({
          'width': xAxisWidth.toString(),
          'height': yAxisHeight.toString(),
          /* Use MARGIN - 1 for the chart ifself to not overlap with the axis */
          'transform': 'translate(${offsetX}, ${MARGIN - 1})'
        });
        s.renderer.render(group);
        group.attributes['class'] = 'series-group';
      });

      /* A series that was rendered earlier isn't there anymore, remove it */
      selection.exit.remove();
    });

    /*
     * TODO(prsd): Ensure that all series that use the same axis also
     * have columns that are of the same type.
     */

    /* Set extent on each measure axes */
    _measureAxisUsers.forEach((id, listOfSeries) {
      var sampleCol = listOfSeries.first.measures.first,
          sampleColSpec = data.columns.elementAt(sampleCol),
          measureAxis = _measureAxes[id];

      measureAxis.scale = sampleColSpec.createDefaultScale();
      if (measureAxis.tickFormatter == null) {
        measureAxis.tickFormatter = sampleColSpec.formatter;
      }
      if (sampleColSpec.useOrdinalScale) {
        /* TODO(prsd): Ordinal measure scale */
      } else {
        var lowest = min(listOfSeries.map((s) => s.renderer.extent.min)),
            highest = max(listOfSeries.map((s) => s.renderer.extent.max));

        // Use default domain if lowest and highest are the same, right now
        // lowest is always 0, change to lowest when we make use of it.
        if (highest != 0) {
          /* TODO(prsd): What happens when the minimum value is negative */
          _measureAxes[id].domain = [0, highest];
        }
      }
    });

    /*
     * Draw upto two measure axes.
     * TODO(prsd): Evaluate if selection of drawn axis should be part
     *     of config rather than being the first two to be created.
     */
    var measureAxesCount = dimensionAxesCount == 1 ? MEASURE_AXES_COUNT : 0,
        displayed = _measureAxes.keys.take(measureAxesCount);

    /* Build a list of dimension axes that use range bands */
    dimensionsUsingBands.clear();
    series.forEach((ChartSeries s) =>
        dimensionsUsingBands.addAll(s.renderer.dimensionsUsingBand));

    /* Width of rendering = (width - space used by vertical axes) */
    if (dimensionAxesCount == 2) xAxisWidth -= config.yAxisWidth;
    xAxisWidth -= (displayed.length * config.yAxisWidth);

    /* Display the dimension axes */
    var displayedDimAxes = config.dimensions.take(dimensionAxesCount),
        dimAxisGroups = _svg.selectAll('.dim-group').data(displayedDimAxes),
        hasLeftAxis = (dimensionAxesCount == 2) ||
            (dimensionAxesCount == 1 && displayed.length != 0),
        seriesUsingBands = series.where(
            (s) => !isNullOrEmpty(s.renderer.dimensionsUsingBand));

    /* Display measure axes if we need to */
    if (measureAxesCount > 0) {
      var axisGroups = _svg.selectAll('.measure-group').data(displayed);

      /* Update measure axis (add/remove/update) */
      axisGroups.enter.append('svg:g');
      axisGroups
          ..attr('width', config.yAxisWidth)
          ..attr('height', yAxisHeight)
          ..attrWithCallback('transform', (axisId, index, group) {
              var offsetX = index == 0 ? config.yAxisWidth + MARGIN : width -
                  (MARGIN + config.yAxisWidth) * (displayed.length - index);
              return 'translate(${offsetX}, ${MARGIN})';
            })
          ..each((axisId, index, group) {
              _measureAxes[axisId]
                  ..isMeasureAxis = true
                  ..orientation = index == 0 ?
                      ChartAxis.ORIENTATION_LEFT : ChartAxis.ORIENTATION_RIGHT
                  ..draw(this, group);

              group.classes.clear();
              group.classes.addAll(['measure-group','measure-${index}']);
            });
      axisGroups.exit.remove();
    }


    offsetX = (hasLeftAxis ? config.yAxisWidth : 0) + MARGIN;
    offsetY = height -
        (MARGIN + (displayedDimAxes.length > 0 ? config.xAxisHeight : 0));

    // Update dimension axes (add new / remove old / update remaining)
    // TODO(prsd): We may be doing unnecessary re-initialization here.
    dimAxisGroups.enter.append('svg:g');
    dimAxisGroups
        ..attrWithCallback('width',
            (d,i,e) => i == 0 ? xAxisWidth : config.yAxisWidth)
        ..attrWithCallback('height',
            (d,i,e) => i == 0 ? config.xAxisHeight : yAxisHeight)
        ..attr('transform', 'translate($offsetX,$offsetY)')
        ..each((column, index, group) {
            var axis = getDimensionAxis(
                    ChartArea.DIMENSION_AXIS_IDS[index], force:true),
                colSpec = data.columns.elementAt(column),
                usingBands = dimensionsUsingBands.contains(index),
                defaultOuterPadding =
                    usingBands ? theme.bandOuterPadding : theme.outerPadding,
                defaultInnerPadding =
                    usingBands ? theme.bandInnerPadding : 1.0,
                outerPadding = seriesUsingBands.fold(defaultOuterPadding,
                    (old, next) =>
                        math.min(old, next.renderer.bandOuterPadding)),
                innerPadding = seriesUsingBands.fold(defaultInnerPadding,
                    (old, next) =>
                        math.min(old, next.renderer.bandInnerPadding)),
                values = data.rows.map((row) => row.elementAt(column)),
                minMax = extent(values);

            axis..outerPadding = outerPadding
                ..innerPadding = innerPadding
                ..orientation = (index == 0) ?
                    ChartAxis.ORIENTATION_BOTTOM : ChartAxis.ORIENTATION_LEFT
                ..scale = colSpec.createDefaultScale()
                ..isOrdinalScale = colSpec.useOrdinalScale
                ..usingRangeBands = usingBands
                ..domain = colSpec.useOrdinalScale ?
                    values.toList() : [minMax.min, minMax.max];

            if (axis.tickFormatter == null) {
              axis.tickFormatter = colSpec.formatter;
            }
            if (config.dimensionTickNumbers != null) {
              axis.ticks = (config.dimensionTickNumbers as List)[index];
            }
            axis.draw(this, group);

            group.classes.clear();
            group.classes.addAll(['dim-group', 'dim-${index}']);
          });
    dimAxisGroups.exit.remove();

    axesDomainCompleter.complete();

    // Save the list of valid series to be used with legend.
    _series = series;

    // Only update the legend when with the config changed or when drawing
    // for the first time, or the data is changed when renderer is pie chart.
    _updateLegend();
  }
}
