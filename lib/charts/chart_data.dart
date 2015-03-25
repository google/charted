/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

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

  @override
  String toString();
}

/**
 * Interface implemented by [ChartData] transformers.
 * Examples:
 *   AggregationTranformer to aggregations rows/columns
 *   FilterTransformer to filter data
 *   TransposeTransformer to convert rows to columns and vice-versa
 */
abstract class ChartDataTransform {
  /**
   * Create a new instance of [ChartData] by selecting a subset
   * of rows and columns from the current one
   */
  ChartData transform(ChartData source);
}

/**
 * Implementation of [ChangeRecord], that is used to notify when rows get added
 * or removed to ChartData
 */
class ChartRowChangeRecord implements ChangeRecord {
  /**
   * Changes to the rows - contains all updates to rows since last notification.
   */
  final List<ListChangeRecord> changes;

  const ChartRowChangeRecord(this.changes);
}

/**
 * Implementation of [ChangeRecord], that is used to notify changes to
 * values in [ChartData].
 */
class ChartValueChangeRecord implements ChangeRecord {
  /**
   * Row that changes.
   */
  final int row;

  /**
   * List of changes to data on the row - includes all updates since the
   * last change notification.
   */
  final List<ListChangeRecord> changes;

  const ChartValueChangeRecord(this.row, this.changes);
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
  final FormatFunction formatter;

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
