/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Interface to be implemented by data providers to give tabular access to
 * data for waterfall chart renderer.
 */
abstract class WaterfallChartData extends ChartData {
  /**
   * Create a new instance of [ChartData]'s internal implementation
   */
  factory WaterfallChartData(Iterable<ChartColumnSpec> columns,
      Iterable<Iterable> rows, [Iterable<int> baseRows]) =>
    new _WaterfallChartData(columns, rows, baseRows);

  /**
   * Set of row indices that are drawn as base (no shifting on y-axis).
   */
  Iterable<int> baseRows;
}
