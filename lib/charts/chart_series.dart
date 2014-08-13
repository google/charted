/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * A [ChartSeries] represents one or more columns in ChartData that are
 * rendered together.
 *
 * Examples:
 * 1. For bar-chart or line-chart, a series consists of one column
 * 2. For stacked chart or grouped bar chart, a series has more than columns
 */
class ChartSeries {
  /** Name of the series */
  final String name;

  /**
   * Optional Ids of measure axes.
   *
   * When specified renderers scale the column values against the ranges
   * of the given axes. If an axis with a matching Id does not exist in
   * [ChartArea] a new axis is created.
   *
   * When not specified, renderers may use [ChartArea.defaultMeasureAxis]
   * where ever necessary.  Refer to the implementation of [ChartRenderer] for
   * more information on defaults and how the measure axes are used.
   *
   * If the implementation is [Observable] and [measureAxisIds] is set to an
   * [ObservableList], changes to the list must be broadcasted.
   */
  Iterable<String> measureAxisIds;

  /**
   * List of columns in ChartData that are measures of this series.
   *
   * A series may include more than one measure if the renderer supports it.
   * When there are more measures than what the renderer can handle, a renderer
   * only renders the first "supported number" of columns. If the number of
   * columns is less than the minimum that the renderer supports, the remaining
   * measures are assumed to have zeros.
   *
   * If the implementation is [Observable] and [measures] is set to an
   * [ObservableList], changes to the list must be broadcasted.
   */
  Iterable<int> measures;

  /**
   * Instance of the renderer used to render the series.
   *
   * [ChartArea] creates a renderer using [ChartRender.create] and uses it
   * to compute range of the measure axis and to render the chart.
   */
  ChartRenderer renderer;

  /**
   * Factory function to create an instance of internal implementation of
   * [ChartSeries].
   */
  factory ChartSeries(String name, Iterable<int> measures,
      ChartRenderer renderer, { Iterable<String> measureAxisIds : null })
          => new _ChartSeries(name, measures, renderer, measureAxisIds);
}

/**
 * Implementation of [ChangeRecord] that is used to notify changes to
 * [ChartSeries].  Currently, only changes to measures and measureAxisIds
 * are supported.
 */
class ChartSeriesChangeRecord implements ChangeRecord {
  /**
   * Reference to series that changed
   */
  final ChartSeries series;

  const ChartSeriesChangeRecord(this.series);
}