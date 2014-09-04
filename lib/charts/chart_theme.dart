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
  static ChartTheme current = new QuantumChartTheme();

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

  /**
   * Width of the separator between two chart elements.
   * Used to separate pies in pie-chart, bars in grouped and stacked charts.
   */
  int get defaultSeparatorWidth => 1;

  /**
   * Stroke width used by all shapes.
   * It also used when computing width of the by the renderers.
   */
  int get defaultStrokeWidth => 2;

  /** Easing function for the transition */
  EasingFn  get transitionEasingType => Transition.defaultEasingType;

  /** Easing mode for the transition */
  EasingMode get transitionEasingMode => Transition.defaultEasingMode;

  /** Total duration of the transision in milli-seconds */
  int get transitionDuration => 250;

  /** Theme passed to the measure axes */
  ChartAxisTheme get measureAxisTheme;

  /** Theme passed to the dimension axes */
  ChartAxisTheme get dimensionAxisTheme;
}

abstract class ChartAxisTheme {
  /**
   * Treshold for tick length.  Setting [axisTickSize] <= [FILL_RENDER_AREA]
   * will make the axis span the entire height/width of the rendering area.
   */
  static const int FILL_RENDER_AREA = SMALL_INT_MIN;

  /**
   * Number of ticks displayed on the axis - only used when an axis is
   * using a quantitative scale.
   */
  int get axisTickCount;

  /**
   * Size of ticks on the axis. When [measureTickSize] <= [FILL_RENDER_AREA],
   * the painted tick will span complete height/width of the rendering area.
   */
  int get axisTickSize;

  /** Space between axis and label for dimension axes */
  int get axisTickPadding;

  /**
   * Space between the first tick and the measure axes.
   * Only used on charts that don't have renderers that use "bands" of space
   * on the dimension axes
   *
   * Represented as a percentage of space between two consecutive ticks. The
   * space between two consecutive ticks is also known as the segment size.
   */
  double get axisOuterPadding;

  /**
   * Space between the two bands in the chart.
   * Only used on charts that have renderers that use "bands" of space on the
   * dimension axes.
   *
   * Represented as a percentage of space between two consecutive ticks. The
   * space between two consecutive ticks is also known as the segment size.
   */
  double get axisBandInnerPadding;

  /**
   * Space between the first band and the measure axis.
   * Only used on charts that have renderers that use "bands" of space on the
   * dimension axes.
   *
   * Represented as a percentage of space between two consecutive ticks. The
   * space between two consecutive ticks is also known as the segment size.
   */
  double get axisBandOuterPadding;

  /** When set to true, the axes resize to fit the labels. */
  bool get axisAutoResize => true;

  /**
   * Width of vertical axis when it is not resizing automatically. If
   * [autoResizeAxis] is set to true, [verticalAxisWidth] will be used as the
   * maximum width of the vertical axis.
   *
   * Height of vertical axis is automatically computed based on height of the
   * visualization.
   */
  int get verticalAxisWidth => 200;

  /**
   * Height of horizontal axis when it is not resizing automatically. If
   * [autoResizeAxis] is set to true [horizontalAxisHeight] is used as the
   * maximum height of the horizontal axis.
   *
   * Width of horizontal axis is automatically computed based on width of the
   * visualization.
   */
  int get horizontalAxisHeight => 200;
}
