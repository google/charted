/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

typedef bool FilterFn(int index, Iterable row);

/**
 * Interface to be implemented by data providers to give tabular access to
 * data for chart renderers.
 */
abstract class ChartData {
  /**
   * Create a new instance of [ChartData]'s internal implementation
   */
  factory ChartData(Iterable<ChartColumnSpec> columns, Iterable<Iterable> rows)
      => new _ChartData(columns, rows);

  /** Read-only access to column specs */
  Iterable<ChartColumnSpec> get columns;

  /** Read-only access to rows */
  Iterable<Iterable> get rows;
}

/**
 * Interface implemented by [ChartData] implementations that support filtering
 * of columns and rows.
 */
abstract class ChartDataFilter {
  /**
   * Create a new instance of [ChartData] by selecting a subset
   * of rows and columns from the current one
   */
  ChartData filter(FilterFn rowFilterFn, FilterFn columnFilterFn);
}

/**
 * Interface implemented by [ChartData] implementations that support group by
 * column values
 */
abstract class ChartDataGroupBy {
  /**
   * Create a new instance of [ChartData] by grouping rows by
   * the specified fields
   */
  ChartData groupBy(Iterable<num> indices);
}

/**
 * Interface to be implemented by [ChartData] implementations
 * that support observing changes to data.
 */
abstract class ChartDataObservable {
  /**
   * Stream on which changes to the rows list (adding/removing a row)
   * are notified. Each update on the stream has a list of rows added
   * and list of rows removed since the last update.
   */
  Stream<ListChangeRecord> get onRowsChanged;

  /**
   * Stream on which data changes are announced. Each update includes
   * the columns and row index of the value that got changed
   */
  Stream<ChartedPair<int,ListChangeRecord>> get onValuesUpdated;
}

/**
 * Meta information for each column in ChartData
 */
class ChartColumnSpec {
  static const String TYPE_BOOLEAN = 'boolean';
  static const String TYPE_DATE = 'date';
  static const String TYPE_NUMBER = 'number';
  static const String TYPE_STRING = 'string';
  static const String TYPE_TIMESTAMP = 'timestamp';

  static const List ORDINAL_SCALES = const [ TYPE_STRING ];
  static const List LINEAR_SCALES = const [ TYPE_NUMBER ];
  static const List TIME_SCALES = const [ TYPE_DATE, TYPE_TIMESTAMP ];

  /** Formatter for values that belong to this column */
  final Formatter formatter;

  /**
   * Label for the column.  Used in legend, tooltips etc;
   * When not specified, defaults to empty string.
   */
  final String label;

  /**
   * Type of data in this column. Used for interpolations, computing
   * scales and ranges. When not specified, it is assumed to be "number"
   * for measures and "string" for dimensions.
   */
  final String type;

  /**
   * Indicates if this column requires an ordinal scale.  Ordinal scales
   * directly map the input value to one output value (i.e they do not
   * use interpolations to compute the values.  Eg: City names)
   *
   * If not specified, an ordinal scale is used for string columns and
   * interpolated scales are used for others.
   */
  final bool useOrdinalScale;

  /**
   * Initialize axis scale according to [ChartColumnSpec] type.
   * This logic is extracted from [ChartArea] implementation for conveniently
   * adding more scale types.
   */
  Scale createDefaultScale() {
    if (useOrdinalScale == true) return new OrdinalScale();
    if (LINEAR_SCALES.contains(type)) return new LinearScale();
    if (TIME_SCALES.contains(type)) return new TimeScale();
    return null;
  }

  ChartColumnSpec({this.label, String type : TYPE_NUMBER,
      this.formatter, bool useOrdinalScale})
      : useOrdinalScale = useOrdinalScale == true ||
            useOrdinalScale == null && ORDINAL_SCALES.contains(type),
        type = type;
}
