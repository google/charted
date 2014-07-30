/**
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
   * List of series to visualize on this chart. Setting a new list
   * or adding/removing items from this list will broadcast a change.
   *
   * If [series] is set to an [ObservableList], changes to the list
   * are broadcast over [changes], which [ChartArea] uses to refresh the chart
   */
  Iterable<ChartSeries> series;

  /**
   * List of columns that form the dimensions on the chart. Setting
   * a new list or adding/removing items from this list will broadcast
   * a change.
   *
   * If [dimensions] is set to an [ObservableList], changes to the list
   * are broadcast over [changes], which [ChartArea] uses to refresh the chart
   */
  Iterable<int> dimensions;

  /**
   * User defined number of tick numbers for each dimension axis.
   * This is only a suggestion value, which itself might not be used
   * during rendering.
   */
  Iterable<int> dimensionTickNumbers;

  /** Implementation of [ChartLegend] that will be used to draw the legend */
  ChartLegend legend;

  /**
   * Stream on which changes are broadcast.  ChartData implementations
   * must listen to this stream and update the chart.
   */
  Stream<ChartConfig> get changes;

  /** Total width of the chart - includes data and axis areas */
  int width;

  /** Height of the chart - includes data and axis areas */
  int height;

  /** Width allocated to the y-axis */
  int yAxisWidth;

  /** Height allocated to the x-axis */
  int xAxisHeight;

  /* TODO(prsd,midoringo): Find a nice name */
  /** Indicates if the chart has primary dimension on the left axis */
  bool isRotated;

  /** Factory method to create an instance of the default implementation */
  factory ChartConfig(Iterable<ChartSeries> series, Iterable<int> dimensions,
      {Iterable<int> dimensionTickNumbers}) => new _ChartConfig(
          series, dimensions, dimensionTickNumbers: dimensionTickNumbers);
}
