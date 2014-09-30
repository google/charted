/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Given a DOM element, [ChartArea] takes care of rendering the axis and
 * passing relevant parameters to chart renderers that draw the actual
 * data visualizations.
 */
abstract class ChartArea implements ChartBehaviorSource {
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
   * Theme for this chart. Any changes to [theme] are not applied to the chart
   * until it is redrawn. Changes can be forced by calling [draw] function.
   */
  ChartTheme theme;

  /**
   * When set to true, the chart subscribes to changes on data and updates the
   * chart when [data] or [config] changes. Defaults to false.
   */
  bool autoUpdate;

  /**
   * Number of dimension axes that this area contains.
   * Examples:
   *   - A bar-chart has one dimension axis (typically the 'x' axis)
   *   - A bubble-chart has two dimension axis (both 'x' and 'y')
   *   - A pie-chart does not have any axis
   *
   * Currently, the only valid values are 0, 1 and 2.
   */
  int dimensionAxesCount;

  /**
   * Geometry of components in this [ChartArea]
   */
  ChartAreaLayout get layout;

  /**
   * Scales used to render the measure axis of the given [ChartSeries]
   */
  Iterable<Scale> measureScales(ChartSeries s);

  /**
   * Scales used to render the dimension axes
   */
  Iterable<Scale> get dimensionScales;

  /**
   * Host of the ChartArea
   */
  Element get host;

  /**
   * Draw the chart with current data and configuration.
   */
  void draw();

  /*
   * Force destroy the ChartArea.
   *   - Clear references to all passed objects and subscriptions.
   *   - Call dispose on all renderers and behaviors.
   */
  void dispose();

  /**
   * Factory method to create an instance of the default implementation
   *   - [host] is the hosting element for the chart. The default
   *       implementation uses a HTML Element that has [Element.clientHeight]
   *       and [Element.clientWidth] defined.
   *   - [data] is an implementation of [ChartData] that is rendered.
   *   - [config] is an implementation of [ChartData]
   *   - [autoUpdate] indicates if the charts must be updated upon changes
   *       to data and config.  If set to false, the chart isn't updated
   *       until [draw] is called.
   *   - [dimensionAxesCount] indicates the number of dimension axis
   *       displayed in the chart - currently, only 0, 1 and 2 are supported.
   */
  factory ChartArea(host, ChartData data, ChartConfig config,
      {bool autoUpdate: false, int dimensionAxesCount: 1}) =>
          new _ChartArea(host, data, config, autoUpdate, dimensionAxesCount);
}

/**
 * Class representing geometry of the [ChartArea] and various components
 * that are created by the ChartArea.
 */
abstract class ChartAreaLayout {
  /** Sizes of the axes by orientation */
  UnmodifiableMapView<String, Rect> get axes;

  /** Size of render area */
  Rect get renderArea => new Rect();

  /** Size of chart area */
  Rect get chartArea => new Rect();
}
