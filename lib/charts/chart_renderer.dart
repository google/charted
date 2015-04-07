//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Renders the chart on a compatible [ChartArea].
///
abstract class ChartRenderer extends ChartRendererBehaviorSource {
  /// Returns extent of the series. This extent is used by [ChartArea] to
  /// set the output range of the corresponding scale/axis of the series.
  ///
  /// Extent has valid values only if [prepare] was already called.
  Extent get extent;

  /// Indicates if this renderer uses range "band" on any of the dimension
  /// axis. Band is space taken on the dimension axis (if more than a point).
  ///
  /// Examples:
  ///   A bar chart takes up space (width of the bar) on the dimension axis.
  ///   A line chart does not take any space
  Iterable<int> get dimensionsUsingBand;

  /// Hint for padding between two bands that [ChartArea] will use for layout.
  /// This getter is called only for renderers that have [dimensionsUsingBand]
  /// set to non-empty list.
  double get bandInnerPadding;

  /// Hint for padding before first and after the last bands
  /// This getter is called only for renderers that have [dimensionsUsingBand]
  /// set to non-empty list.
  double get bandOuterPadding;

  /// Prepare the chart for rendering.
  /// - [area] represents the [ChartArea] on which the chart is rendered.
  /// - [series] represents the [ChartSeries] that is rendered
  bool prepare(ChartArea area, ChartSeries series);

  /// Render series data on the passed [host].
  /// Draw will not be successful if [prepare] was not already called.
  void draw(Element host, {Future schedulePostRender});

  /// Clears DOM created by this renderer and releases
  /// references to passed objects.
  void dispose();
}
