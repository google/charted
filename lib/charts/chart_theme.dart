//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// Theme used to render the chart area, specifically colors and axes.
///
/// Typical implementations of ChartTheme also implement theme interfaces
/// used by the renderers, tooltips, legends and any other behaviors.
abstract class ChartTheme {
  static ChartTheme current = new QuantumChartTheme();

  /// Column/series when it is disabled, possibly because another is active
  static const int STATE_INACTIVE = 0;

  /// Column/Series that is normal
  static const int STATE_NORMAL = 1;

  /// Column/series that is active, possibly by a click
  static const int STATE_ACTIVE = 2;

  /// Color that can be used for key.
  /// For a given input key, the output is always the same.
  String getColorForKey(key, [int state]);

  /// Markup for filters that is added to all chart elements. These filters
  /// can be referenced using url() in values returned by [getFilterForState].
  String get filters;

  /// Returns any filters that must be applied based on the element's state
  String getFilterForState(int state);

  /// Color for overflow and other items.
  /// For example, the collect all bucket used by pie-chart.
  String getOtherColor([int state]);

  /// Width of the separator between two chart elements.
  /// Used to separate pies in pie-chart, bars in grouped and stacked charts.
  int get defaultSeparatorWidth => 1;

  /// Stroke width used by all shapes.
  int get defaultStrokeWidth => 2;

  /// Default font for computation of text metrics
  String get defaultFont;

  /// Easing function for the transition
  EasingFunction get transitionEasingType => Transition.defaultEasingType;

  /// Easing mode for the transition
  EasingModeFunction get transitionEasingMode => Transition.defaultEasingMode;

  /// Total duration of the transition in milli-seconds
  int get transitionDurationMilliseconds => 250;

  /// Theme passed to the measure axes - only used by cartesian charts
  ChartAxisTheme getMeasureAxisTheme([Scale scale]) => null;

  /// Theme passed to the dimension axes - only used by cartesian charts
  ChartAxisTheme getDimensionAxisTheme([Scale scale]) => null;

  /// Padding around the rendered chart. Defaults to 10px in all directions
  AbsoluteRect get padding => const AbsoluteRect(10, 10, 10, 10);
}

abstract class ChartAxisTheme {
  /// Treshold for tick length.  Setting [axisTickSize] <= [FILL_RENDER_AREA]
  /// will make the axis span the entire height/width of the rendering area.
  static const int FILL_RENDER_AREA = SMALL_INT_MIN;

  /// Number of ticks displayed on the axis - only used when an axis is
  /// using a quantitative scale.
  int get axisTickCount;

  /// Size of ticks on the axis. When [measureTickSize] <= [FILL_RENDER_AREA],
  /// the painted tick will span complete height/width of the rendering area.
  int get axisTickSize;

  /// Space between axis and label for dimension axes
  int get axisTickPadding;

  /// Space between the first tick and the measure axes in pixels.
  /// Only used on charts that don't have renderers that use "bands" of space
  /// on the dimension axes
  double get axisOuterPadding;

  /// Space between the two bands in the chart.
  /// Only used on charts that have renderers that use "bands" of space on the
  /// dimension axes.
  ///
  /// Represented as a percentage of space between two consecutive ticks. The
  /// space between two consecutive ticks is also known as the segment size.
  double get axisBandInnerPadding;

  /// Space between the first band and the measure axis in pixels.
  /// Only used on charts that have renderers that use "bands" of space on the
  /// dimension axes.
  double get axisBandOuterPadding;

  /// When set to true, the vertical axes resize to fit the labels.
  bool get verticalAxisAutoResize => true;

  /// Width of vertical axis when it is not resizing automatically. If
  /// [autoResizeAxis] is set to true, [verticalAxisWidth] will be used as the
  /// maximum width of the vertical axis.
  ///
  /// Height of vertical axis is automatically computed based on height of the
  /// visualization.
  int get verticalAxisWidth => 200;

  /// Max height of horizontal axis, this is used when the axis label need to be
  /// rotated.  If rotated label would be ellipsed if the height is greater than
  /// this value. Width of horizontal axis is automatically computed based on
  /// width of the visualization.
  int get horizontalAxisHeight => 200;

  /// Font used by axis ticks. When specified, axis uses efficient off-screen
  /// computation of text metrics.
  ///
  /// Font string must be of the following form:
  ///   "bold italic 16px Roboto"
  ///   "bold 16px Roboto"
  ///   "italic 16px Roboto"
  ///   "16px Roboto"
  ///
  /// When not specified, SVGTextElement's metrics API will be used.
  String get ticksFont => null;
}
