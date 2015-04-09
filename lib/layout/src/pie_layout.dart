/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.layout;

/**
 * Utility class to create arc definitions that can be used by the SvgArc
 * to generate arcs for pie and donut charts
 */
class PieLayout {
  /**
   * Callback to convert datum to values used for layout
   * Defaults to [defaultValueAccessor]
   */
  SelectionValueAccessor<num> accessor = defaultValueAccessor;

  /**
   * Callback to get the start angle for the pie. This callback is
   * called once per list of value (i.e once per call to [layout])
   * Defaults to [defaultStartAngleCallback]
   */
  SelectionCallback<num> startAngleCallback = defaultStartAngleCallback;

  /**
   * Callback to get the start angle for the pie. This callback is
   * called once per list of value (i.e once per call to [layout])
   * Defaults to [defaultEndAngleCallback]
   */
  SelectionCallback<num> endAngleCallback = defaultEndAngleCallback;

  /**
   * Comparator that is used to set the sort order of values. If not
   * specified, the input order is used.
   */
  Comparator<num> compare = null;

  /**
   * Return a list of SvgArcData objects that could be used to create
   * arcs in a pie-chart or donut-chart.
   */
  List layout(List data, [int ei, Element e]) {
    var values = new List.generate(data.length,
            (int i) => accessor(data[i], i)),
        startAngle = startAngleCallback(data, ei, e),
        endAngle = endAngleCallback(data, ei, e),
        total = sum(values),
        scaleFactor = (endAngle - startAngle) / (total > 0 ? total : 1),
        index = new Range.integers(values.length).toList(),
        arcs = new List(data.length);

    if (compare != null) {
      index.sort((left, right) => compare(data[left], data[right]));
    }

    int count = 0;
    index.forEach((i) {
      endAngle = startAngle + values[i] * scaleFactor;
      arcs[count++] = new SvgArcData(data[i], values[i], startAngle, endAngle);
      startAngle = endAngle;
    });

    return arcs;
  }

  /** Sets a constant value to start angle of the layout */
  set startAngle(num value) =>
      startAngleCallback = toCallback(value);

  /** Sets a constant value to end angle of the layout */
  set endAngle(num value) =>
      endAngleCallback = toCallback(value);

  /** Default value accessor */
  static num defaultValueAccessor(num d, i) => d;

  /** Default start angle callback - returns 0 */
  static num defaultStartAngleCallback(d, i, _) => 0;

  /** Default end angle calback - returns 2 * PI */
  static num defaultEndAngleCallback(d, i, _) => 2 * PI;
}
