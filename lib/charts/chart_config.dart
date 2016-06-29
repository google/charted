//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Configuration of the chart.
///
abstract class ChartConfig {
  /// List of series rendered on this chart.
  ///
  /// If the implementation is observable, setting a new list must broadcast
  /// a change.  Additionally, if [series] is set to an [ObservableList],
  /// changes to the list are broadcast too.
  Iterable<ChartSeries> series;

  /// List of columns that form the dimensions on the chart.
  ///
  /// If the implementation is observable, setting a new list must broadcast
  /// a change. Additionally, if [dimensions] is set to an [ObservableList],
  /// changes to the list are broadcast too.
  Iterable<int> dimensions;

  /// Instance of [ChartLegend] that is used to render legend.
  ChartLegend legend;

  /// Recommended minimum size for the chart
  Rect minimumSize;

  /// Indicates if the chart has primary dimension on the left axis
  bool isLeftAxisPrimary = false;

  /// Registers axis configuration for the axis represented by [id].
  void registerMeasureAxis(String id, ChartAxisConfig axis);

  /// User-set axis configuration for [id], null if not set.
  ChartAxisConfig getMeasureAxis(String id);

  /// Register axis configuration of the axis used for dimension [column].
  void registerDimensionAxis(int column, ChartAxisConfig axis);

  /// User set axis configuration for [column], null if not set.
  ChartAxisConfig getDimensionAxis(int column);

  /// Measure axes ids that are displayed. If not specified, the first two
  /// measure axes are displayed. If the list is empty, none of the measure
  /// axes are displayed.
  Iterable<String> displayedMeasureAxes;

  /// Indicates if the dimension axes should be drawn on this chart. Unless set
  /// to "false", the axes are rendered.
  bool renderDimensionAxes;

  /// When set to true, the chart rendering changes to be more suitable for
  /// scripts that are written from right-to-left.
  bool isRTL;

  /// Indicate if the horizontal axes and the corresponding scales should
  /// switch direction too.
  /// Example: Time scale on the X axis would progress from right to left.
  bool switchAxesForRTL;

  /// Factory method to create an instance of the default implementation
  factory ChartConfig(Iterable<ChartSeries> series,
      Iterable<int> dimensions) = DefaultChartConfigImpl;
}

///
/// [ChangeRecord] that is used to notify changes to [ChartConfig].
/// Currently, changes to list of dimensions and list of series are monitored.
///
class ChartConfigChangeRecord implements ChangeRecord {
  const ChartConfigChangeRecord();
}

///
/// Configuration for an axis
///
class ChartAxisConfig {
  /// Title for the axis
  String title;

  /// Scale to be used with the axis
  Scale scale;

  /// For a quantitative scale, values at which ticks should be displayed.
  /// When not specified, the ticks are based on the type of [scale] used.
  Iterable tickValues;

  /// Forces the ticks count of a scale to be of the forcedTicksCount.
  /// The tick values on the scale does not guarantee to be niced numbers, but
  /// domain of the scale does.  Only valid for quantitative scale.
  int forcedTicksCount;
}
