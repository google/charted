/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

/**
 * Interface that is implemented by classes that support
 * displaying legend.
 */
abstract class ChartLegend {
  update(Iterable<ChartLegendItem> legend, ChartArea chart);
  factory ChartLegend(Element host) => new _ChartLegend(host);
}

/**
 * Class representing an item in the legend.
 */
class ChartLegendItem {
  /** Index of the column in [ChartData] */
  int column;

  /** HTML color used for this column in the chart */
  String color;

  /** The label of the Legend Item. */
  // TODO (midoringo, prsd): Figure out if this needs to be changed for custom
  // Legend.
  String label;

  /** List of series that this column is part of */
  Iterable<ChartSeries> series;

  /** Utility constructors */
  ChartLegendItem({this.column, this.color, this.label, this.series});
}
