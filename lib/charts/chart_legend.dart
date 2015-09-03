//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Interface that is implemented by classes that support
/// displaying legend.
///
abstract class ChartLegend {
  /// Title of the legend, dynamically updates the legend title when set.
  String title;

  /// Called by [ChartArea] to notify changes to legend.
  update(Iterable<ChartLegendItem> legend, ChartArea chart);

  /// Called by [ChartArea] to dispose selection listeners.
  dispose();

  /// Factory to create an instance of the default implementation.
  factory ChartLegend(Element host,
      {maxItems: 0, title: '', showValues: false}) =>
          new DefaultChartLegendImpl(host, maxItems, showValues, title);
}

///
/// Class representing an item in the legend.
///
class ChartLegendItem {
  /// Index of the row/column in [ChartData]. Legend uses column based coloring
  /// in [CartesianArea] that has useRowColoring set to false and row based
  /// coloring in all other cases.
  int index;

  /// HTML color used for the row/column in chart
  String color;

  /// The label of the item.
  String label;

  /// Description of the item.
  String description;

  /// Pre-formatted value to use as value.
  String value;

  /// List of series that this column is part of
  Iterable<ChartSeries> series;

  ChartLegendItem({this.index, this.color,
      this.label, this.description, this.series, this.value});
}
