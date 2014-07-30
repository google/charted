/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.charts;

/**
 * Given a DOM element, ChartBase takes care of rendering data as
 * per the configuration (specified in ChartConfig).
 */
abstract class ChartArea {
  /**
   * Names used for the measure axis that were created internally
   * by [ChartArea].
   */
  static const List MEASURE_AXIS_IDS = const ['_default'];

  /** Ids given to the two dimension Axis that we currently support. */
  static const List DIMENSION_AXIS_IDS = const ['_primary', '_secondary'];

  /**
   * DOM Element which hosts the chart.  This DOM element should either
   * belong to a display type that supports clientHeight and clientWidth
   * properties.
   */
  final Element host;

  /**
   * Data used by the chart. Chart isn't updated till the next call to
   * draw function if [autoUpdate] is set to false.
   *
   * Setting new value to [data] will update the chart.
   */
  ChartData data;

  /**
   * Configuration for this chart.  ChartBase subscribes to changes on
   * [config] and calls draw upon any changes.
   *
   * Refer to [ChartConfig] for further documentation about which changes
   * are added to the stream, which in turn trigger an update on the chart.
   */
  ChartConfig config;

  /**
   * Theme for this chart.  Any changes to [theme] are not applied to the
   * chart until it is redrawn - can be forced by calling the [draw] function
   */
  ChartTheme theme;

  /**
   * Add an axis used for chart dimensions.  When no axes are added, axes are
   * created as required, based on series configuration and input data
   */
  void setDimensionAxis(String id, ChartAxis axis);

  /**
   * Get a dimension axis associated with the given Id.  When [force] is true,
   * a new axis is created if it does not already exist.
   */
  ChartAxis getDimensionAxis(String id, {bool force: false});

  /**
   * Add an axis used for chart measures. When no axes are added, axes are
   * created as required, based on series configuration and input data
   */
  void setMeasureAxis(String id, ChartAxis axis);

  /**
   * Get a measure axis associated with the given Id.  When [force] is true,
   * a new axis is created if it does not already exist.
   */
  ChartAxis getMeasureAxis(String id, {bool force: false});

  /**
   * When [autoUpdate] is set to true, the chart subscribes to changes on
   * data and updates the chart automically. Defaults to false.
   */
  bool autoUpdate;

  /**
   * Draw the chart with current data and configuration. Changes to [config]
   * and [theme] are not applied until the [draw] method is called. Even
   * changes to data need calling [draw] when [autoUpdate] is not set or [data]
   * isn't [ObserableChartData]
   */
  void draw();

  /**
   * Number of dimension axes that this area contains.
   * Examples:
   *   1. A bar-chart has one dimension axis (typically the 'x' axis)
   *   2. A bubble-chart has two dimension axis (both 'x' and 'y')
   *   3. A pie-chart does not have any axis
   */
  int dimensionAxesCount;

  /** List of dimensions that use range bands */
  Iterable<int> get dimensionsUsingBands;

  /**
   * Width of the horizontal axis. Can be used by ChartAxis and
   * ChartRenderer implementations when required.
   */
  int get xAxisWidth;

  /**
   * Height of the vertical axis. Can be used by ChartAxis and
   * ChartRenderer implementations when required.
   */
  int get yAxisHeight;

  /** Factory method to create an instance of the default implementation */
  factory ChartArea(Element host, ChartData data, ChartConfig config,
      {bool autoUpdate: false, int dimensionAxesCount: 1}) =>
          new _ChartArea(host, data, config, autoUpdate, dimensionAxesCount);
}
