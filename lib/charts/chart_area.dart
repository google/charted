//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Given a DOM element, [ChartArea] takes care of rendering the axis and
/// passing relevant parameters to renderers that draw the visualizations.
///
abstract class ChartArea implements ChartAreaBehaviorSource {
  /// Data used by the chart. Chart isn't updated till the next call to
  /// draw function if [autoUpdate] is set to false.
  ///
  /// Setting new value to [data] will update chart if [autoUpdate] is set.
  ChartData data;

  /// Configuration for this chart.  [ChartArea] subscribes to changes on
  /// [config] and calls draw upon any changes.
  ///
  /// Refer to [ChartConfig] for further documentation about which changes
  /// are added to the stream, which in turn trigger an update on the chart.
  ChartConfig config;

  /// Theme for this chart. Any changes to [theme] are not applied to the chart
  /// until it is redrawn. Changes can be forced by calling [draw] function.
  ChartTheme theme;

  /// When set to true, [ChartArea] subscribes to changes on data and updates
  /// the chart when [data] or [config] changes. Defaults to false.
  bool autoUpdate;

  /// When set to true, [ChartArea] uses both 'x' and 'y' axes for dimensions.
  /// Examples:
  ///   - A bar-chart has one dimension axis (typically the 'x' axis)
  ///   - A bubble-chart has two dimension axis (both 'x' and 'y')
  bool get useTwoDimensionAxes;

  /// Geometry of components in this [ChartArea]
  ChartAreaLayout get layout;

  /// Scales used to render the measure axis of the given [ChartSeries]. Each
  /// series may use more than one measure scale.
  ///
  /// For example, a scatter plot may use different scales for color, shape
  /// and size of the rendering.
  Iterable<Scale> measureScales(ChartSeries s);

  /// Scales used to render the dimension axes. The number of scales returned
  /// is either one or two based on [useTwoDimensions]
  Iterable<Scale> get dimensionScales;

  /// Host element of the ChartArea
  Element get host;

  /// Draw the chart with current data and configuration.
  /// - If [preRender] is set, [ChartArea] attempts to build all non data
  ///   dependant elements of the chart.
  /// - When [schedulePostRender] is not null, non-essential elements/tasks
  ///   of chart building are post-poned until the future is resolved.
  void draw({bool preRender: false, Future schedulePostRender});

  /// Force destroy the ChartArea.
  /// - Clear references to all passed objects and subscriptions.
  /// - Call dispose on all renderers and behaviors.
  void dispose();

  /// Factory method to create an instance of the default implementation
  /// - [host] must be an Element that has clientHeight and clientWidth
  ///   properties defined (i.e cannot be inline elements)
  /// - [data] is an instance of [ChartData]
  /// - [config] is an implementation of [ChartConfig]
  /// - If [autoUpdate] is set, chart is updated when data or config
  ///   change.  When not set, [draw] must be called to update the chart.
  /// - When [useTwoDimensionAxes] is set, the chart uses both 'x' and 'y'
  ///   axes as dimensions.
  factory ChartArea(host, ChartData data, ChartConfig config,
      { bool autoUpdate: false, bool useTwoDimensionAxes: false }) =>
          new CartesianChartArea(host, data, config, autoUpdate, useTwoDimensionAxes);
}

/// Class representing geometry of the [ChartArea] and various components
/// that are created by the ChartArea.
abstract class ChartAreaLayout {
  /// Sizes of axes by orientation
  /// For charts that don't have any axes, the value of [axes] is null.
  Map<String, Rect> get axes;

  /// Size of render area.
  Rect get renderArea => new Rect();

  /// Size of chart area.
  Rect get chartArea => new Rect();
}
