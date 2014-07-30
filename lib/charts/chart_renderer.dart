/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Renders the chart on a compatible [ChartArea].
 */
abstract class ChartRenderer {
  /** Configuration of the series that will be rendered */
  set series(ChartSeries value);

  /**
   * ChartBase on which the chart is rendered. This is also where the renderer
   * would get the data, axes and other configuration from.
   */
  set chart(ChartArea value);

  /**
   * Returns extent of the series. This extent is used by [ChartArea] to
   * set the output range of the corresponding scale/axis of of the series.
   *
   * Both [series] and [chart] must be set before attempting to get the extent.
   */
  Extent get extent;

  /**
   * Render series data on the passed [host].
   * Both [series] and [chart] must be set before render is called.
   */
  void render(Element host);

  /** Clear the chart */
  void clear();

  /** Indicate if the renderer can draw on the passed ChartBase */
  bool isAreaCompatible(ChartArea chart);

  /**
   * Indicates if this renderer uses range "band" on each of the dimension
   * axis. Band is defined as the space taken on the dimension axis.
   *
   * Examples:
   *   A bar chart takes up space (width of the bar) on the dimension axis.
   *   A line chart does not take any space
   */
  Iterable<int> get dimensionsUsingBand;

  /**
   * Hint for padding between two bands that the ChartArea could use. This
   * getter is called only for renderers that have [dimensionsUsingBand]
   * set to true on an axis.
   */
  double get bandInnerPadding;

  /**
   * Hint for padding before the first and after the last bands that the
   * ChartArea could use.  This getter is called only for renderers that have
   * [dimensionsUsingBand] set to true.
   */
  double get bandOuterPadding;
}
