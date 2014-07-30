/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Theme used to render the chart area, specifically colors and axes.
 *
 * Typical implementations of ChartTheme also implement theme interfaces
 * used by the renderers, tooltips, legends and any other behaviors.
 */

abstract class ChartTheme {
  static ChartTheme current = new ChartTheme();

  static const int FULL_LENGTH_TICK = -1000;

  /** Column/series when it is disabled, possibly because another is active */
  static const int STATE_DISABLED = 0;

  /** Column/Series that is normal */
  static const int STATE_NORMAL = 1;

  /** Column/series that is active, possibly by a click */
  static const int STATE_ACTIVE = 2;

  /**
   * Color that can be used for key.
   * For a given input key, the output is always the same.
   */
  String getColorForKey(key, [int state]);

  /** Factory method to create the default implementation */
  factory ChartTheme() => new QuantumChartTheme();

  /** Easing function for the transition */
  String easingType = Transition.EASE_TYPE_CUBIC;

  /** Easing mode for the transition */
  String easingMode = Transition.EASE_MODE_IN_OUT;

  /** Total duration of the transision in milli-seconds */
  int transitionDuration;

  /**
   * Size of the ticks on measure axis.
   * [measureTickSize] <= [FULL_LENGTH_TICK] will draw a ticks that
   * span width/height of the chart area.
   */
  int measureTickSize;

  /**
   * Size of the ticks on dimension axis.
   * [dimensionTickSize] <= [FULL_LENGTH_TICK] will draw ticks that
   * span width/height of the chart area.
   */
  int dimensionTickSize;

  /** Space between axis and label for dimension axes */
  int dimensionTickPadding;

  /** Space between axis and label for measure axes */
  int measureTickPadding;

  /**
   * Space between the first tick and the measure axes.
   * Only used on charts that don't have renderers that use "bands" of space
   * on the dimension axes
   *
   * Represented as a percentage of space between two consecutive ticks. The
   * space between two consecutive ticks is also known as the segment size.
   */
  double outerPadding;

  /**
   * Space between the two bands in the chart.
   * Only used on charts that have renderers that use "bands" of space on the
   * dimension axes.
   *
   * Represented as a percentage of space between two consecutive ticks. The
   * space between two consecutive ticks is also known as the segment size.
   */
  double bandInnerPadding;

  /**
   * Space between the first band and the measure axis.
   * Only used on charts that have renderers that use "bands" of space on the
   * dimension axes.
   *
   * Represented as a percentage of space between two consecutive ticks. The
   * space between two consecutive ticks is also known as the segment size.
   */
  double bandOuterPadding;

  /**
   * Width of the separator between two chart elements.
   * Used to separate pies in pie-chart, bars in grouped and stacked charts.
   */
  int separatorWidth;

  /**
   * Stroke width used by all shapes.  It also used when computing width of the
   * by the renderers.
   */
  int strokeWidth = 0;

  /**
   * Inner radius of the pie chart.  A value of 0 would render a pie chart; any
   * positive number would cause the inner radius of the pie to be the specified
   * number; any negative number would cause the inner radius to be proportional
   * to the number of rows of data being rendered in the pie.
   */
  int innerRadius = -1;
}
