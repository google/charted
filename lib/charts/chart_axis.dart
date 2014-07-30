/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Represents axis on the chart
 */
abstract class ChartAxis {
  static const String ORIENTATION_TOP = 'top';
  static const String ORIENTATION_LEFT = 'left';
  static const String ORIENTATION_BOTTOM = 'bottom';
  static const String ORIENTATION_RIGHT = 'right';

  /** Output range of the scale */
  Iterable domain;

  /** Orientation of the axis. */
  String orientation;

  /** Indicates if this is an ordinal scale */
  bool isOrdinalScale;

  /** Scale for this axis */
  Scale scale;

  /** Number of ticks on the axis (where applicable) */
  int ticks;

  /** Formatters for the ticks. */
  Formatter tickFormatter;

  /** Indicates if this axis is used to measure a value */
  bool isMeasureAxis;

  /** Indicates if the chart uses "bands" on this axis */
  bool usingRangeBands;

  /** Gap between bands for axes that have [usingRangeBands] set */
  double innerPadding;

  /** Gap between the bands and edges of the chart area */
  double outerPadding;

  /** Draw the axis (or update if it was already drawn) */
  void draw(ChartArea area, Element element);

  factory ChartAxis({int ticks:5}) => new _ChartAxis(ticks);
}
