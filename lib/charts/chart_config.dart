/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Configuration of the chart.
 */
abstract class ChartConfig {
  /**
   * List of series to visualize on this chart.
   *
   * If the implementation is observable, setting a new list must broadcast
   * a change.  Additionally, if [series] is set to an [ObservableList],
   * changes to the list are broadcast too.
   */
  Iterable<ChartSeries> series;

  /**
   * List of columns that form the dimensions on the chart.
   *
   * If the implementation is observable, setting a new list must broadcast
   * a change. Additionally, if [dimensions] is set to an [ObservableList],
   * changes to the list are broadcast too.
   */
  Iterable<int> dimensions;

  /** Instance of [ChartLegend] implementation used to render legend */
  ChartLegend legend;

  /** Recommended minimum size for the chart */
  Rect minimumSize;

  /** Indicates if the chart has primary dimension on the left axis */
  bool leftAxisIsPrimary = false;

  /** Registers axis configuration for the axis represented by [id]. */
  void registerMeasureAxis(String id, ChartAxisConfig axis);

  /** Return the user-set axis configuration for [id] */
  ChartAxisConfig getMeasureAxis(String id);

  /** Register axis configuration of the axis used for dimension [column]. */
  void registerDimensionAxis(int column, ChartAxisConfig axis);

  /**
   * Return the user set axis configuration for [column].  If a custom scale
   * was not set, returns null.
   */
  ChartAxisConfig getDimensionAxis(int column);

  /**
   * List of measure axes ids that are displayed. If not specified, the first
   * two measure axes are displayed.  If the list is empty, none of the
   * measure axes are displayed.
   */
  Iterable<String> displayedMeasureAxes;

  /**
   * Indicates if the dimension axes should be drawn on this chart. Unless set
   * to "false", the axes are rendered.
   */
  bool renderDimensionAxes;

  /** Factory method to create an instance of the default implementation */
  factory ChartConfig(Iterable<ChartSeries> series, Iterable<int> dimensions)
      => new _ChartConfig(series, dimensions);
}

/**
 * Implementation of [ChangeRecord] that is used to notify changes to
 * [ChartConfig].  Currently, changes to list of dimensions and list of series
 * are monitored.
 */
class ChartConfigChangeRecord implements ChangeRecord {
  const ChartConfigChangeRecord();
}

/*
 * Configuration for an axis
 */
class ChartAxisConfig {
  /** Title for the axis */
  String title;

  /** Scale to be used with the axis */
  Scale scale;

  /**
   * For a quantitative scale, values at which ticks should be displayed.
   * When not specified, the ticks are intepolated evenly over the output
   * range.
   */
  Iterable tickValues;
}

