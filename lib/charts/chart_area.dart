//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Area for rendering cartesian charts. A cartesian chart creates
/// visualization by carefully placing elements along the dimension
/// and measure axes (in a 2 dimensional plane).
///
/// Some renderers may use additional dimensions that is made visible
/// by size and color of the rendered elements.
///
/// For example:
/// - A bar-chart draws bars indicating a value along measure axis.
/// - A bubble-chart where a circle is positioned across two dimension
///   axes. A bubble-chart may also use color and size of circles to
///   indicate more dimensions.
///
/// In a [CartesianArea], more than one series can be rendered together.
///
abstract class CartesianArea implements ChartArea {
  /// When set to true, [ChartArea] uses both 'x' and 'y' axes for dimensions.
  /// Examples:
  ///   - A bar-chart has one dimension axis (typically the 'x' axis)
  ///   - A bubble-chart has two dimension axis (both 'x' and 'y')
  bool get useTwoDimensionAxes;

  /// Scales used to render the measure axis of the given [ChartSeries]. Each
  /// series may use more than one measure scale.
  ///
  /// For example, a scatter plot may use different scales for color, shape
  /// and size of the rendering.
  Iterable<Scale> measureScales(ChartSeries s);

  /// Scales used to render the dimension axes. The number of scales returned
  /// is either one or two based on [useTwoDimensions]
  Iterable<Scale> get dimensionScales;

  /// List of dimensions using a band of space on the axis
  Iterable<int> get dimensionsUsingBands;

  /// Stream to notify when chart axes get updated.
  Stream<ChartArea> get onChartAxesUpdated;

  /// Factory method to create an instance of the default implementation
  /// - [host] must be an Element that has clientHeight and clientWidth
  ///   properties defined (i.e cannot be inline elements)
  /// - [data] is an instance of [ChartData]
  /// - [config] is an implementation of [ChartConfig]
  /// - If [autoUpdate] is set, chart is updated when data or config
  ///   change.  When not set, [draw] must be called to update the chart.
  /// - When [useTwoDimensionAxes] is set, the chart uses both 'x' and 'y'
  ///   axes as dimensions.
  factory CartesianArea(
      dynamic host,
      ChartData data,
      ChartConfig config, {
      bool autoUpdate: false,
      bool useTwoDimensionAxes: false,
      bool useRowColoring: false,
      ChartState state }) =>
          new DefaultCartesianAreaImpl(host, data, config, autoUpdate,
              useTwoDimensionAxes, useRowColoring, state);
}

///
/// Area for rendering layout charts. A layout chart creates visualization by
/// distributing available space to each measure.
///
/// For example:
/// - A pie-chart distributes a radial area to each measure.
/// - In a tree-map a rectangular area is distributed to each measure.
///
/// In a [LayoutArea], only one series can be rendered and the area does
/// not have any scales and axes.
///
abstract class LayoutArea implements ChartArea {
  /// Layout area always uses row coloring.
  bool get useRowColoring => true;

  factory LayoutArea(
      dynamic host,
      ChartData data,
      ChartConfig config, {
      bool autoUpdate: false,
      ChartState state }) =>
          new DefaultLayoutAreaImpl(host, data, config, autoUpdate, state);
}

///
/// Base interface for all implementations of a chart drawing area.
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

  /// Geometry of components in this [ChartArea]
  ChartAreaLayout get layout;

  /// Host element of the ChartArea
  Element get host;

  /// True when all components of the chart have been updated - either already
  /// drawn or are in the process of transitioning in.
  bool get isReady;

  /// When true, [ChartArea] and renderers that support coloring by row,
  /// use row indices and values to color the chart. Defaults to false.
  bool get useRowColoring;

  /// State of the chart - selection and highlights.
  ChartState get state;

  /// Draw the chart with current data and configuration.
  /// - If [preRender] is set, [ChartArea] attempts to build all non data
  ///   dependant elements of the chart.
  /// - When [schedulePostRender] is not null, non-essential elements/tasks
  ///   of chart building are postponed until the future is resolved.
  void draw({bool preRender: false, Future schedulePostRender});

  /// Force destroy the ChartArea.
  /// - Clear references to all passed objects and subscriptions.
  /// - Call dispose on all renderers and behaviors.
  void dispose();
}

///
/// Class representing geometry of the [ChartArea] and various components
/// that are created by the ChartArea.
///
abstract class ChartAreaLayout {
  /// Sizes of axes by orientation.
  /// Only valid on [CartesianArea], null otherwise.
  Map<String, Rect> get axes;

  /// Size of render area.
  Rect get renderArea => new Rect();

  /// Size of chart area.
  Rect get chartArea => new Rect();
}
