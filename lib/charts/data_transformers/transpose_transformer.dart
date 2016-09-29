//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// Transforms the ChartData by transposing the columns and rows.  A label column
/// index in the original data will need to be specified (default to 0), all
/// values in the specified label column will be used as the label for the
/// transformed data, all the labels in the original Chart data columns will be
/// populated in the label column as values of that column.
///
/// All values in the data except for the data in the label column must have the
/// same type; All columns except for the label column must have the same
/// formatter if a formatter exist for columns.
class TransposeTransformer extends Observable
    implements ChartDataTransform, ChartData {
  final SubscriptionsDisposer _dataSubscriptions = new SubscriptionsDisposer();
  ObservableList<ChartColumnSpec> columns = new ObservableList();
  ObservableList<List> rows = new ObservableList();

  // If specified, this values of this column in the input chart data will be
  // used as labels of the transposed column label.  Defaults to first column.
  int _labelColumn;
  ChartData _data;

  TransposeTransformer([this._labelColumn = 0]);

  /// Transforms the input data with the specified label column in the
  /// constructor.  If the ChartData is Observable, changes fired by the input
  /// data will trigger transform to be performed again to update the output rows
  /// and columns.
  ChartData transform(ChartData data) {
    _data = data;
    _registerListeners();
    _transform();
    return this;
  }

  /// Registers listeners if input ChartData is Observable.
  _registerListeners() {
    _dataSubscriptions.dispose();

    if (_data is Observable) {
      var observable = (_data as Observable);
      _dataSubscriptions.add(observable.changes.listen((records) {
        _transform();

        // NOTE: Currently we're only passing the first change because the chart
        // area just draw with the updated data.  When we add partial update
        // to chart area, we'll need to handle this better.
        notifyChange(records.first);
      }));
    }
  }

  /// Performs the transpose transform with _data.  This is called on transform
  /// and on changes if ChartData is Observable.
  _transform() {
    // Assert all columns are of the same type and formatter, excluding the
    // label column.
    var type;
    FormatFunction formatter;
    for (var i = 0; i < _data.columns.length; i++) {
      if (i != _labelColumn) {
        if (type == null) {
          type = _data.columns.elementAt(i).type;
        } else {
          assert(type == _data.columns.elementAt(i).type);
        }
        if (formatter == null) {
          formatter = _data.columns.elementAt(i).formatter;
        } else {
          assert(formatter == _data.columns.elementAt(i).formatter);
        }
      }
    }

    columns.clear();
    rows.clear();
    rows.addAll(new List<List>.generate(_data.columns.length - 1, (i) => []));

    // Populate the transposed rows' data, excluding the label column, visit
    // each value in the original data once.
    var columnLabels = [];
    for (var row in _data.rows) {
      for (var i = 0; i < row.length; i++) {
        var columnOffset = (i < _labelColumn) ? 0 : 1;
        if (i != _labelColumn) {
          rows.elementAt(i - columnOffset).add(row.elementAt(i));
        } else {
          columnLabels.add(row.elementAt(i));
        }
      }
    }

    // Transpose the ColumnSpec's label into the column where the original
    // column that is used as the new label.
    for (var i = 0; i < rows.length; i++) {
      var columnOffset = (i < _labelColumn) ? 0 : 1;
      rows.elementAt(i).insert(
          _labelColumn, _data.columns.elementAt(i + columnOffset).label);
    }

    // Construct new ColumnSpaces base on the label column.
    for (var label in columnLabels) {
      columns.add(
          new ChartColumnSpec(type: type, label: label, formatter: formatter));
    }
    columns.insert(
        _labelColumn,
        new ChartColumnSpec(
            type: ChartColumnSpec.TYPE_STRING,
            label: _data.columns.elementAt(_labelColumn).label));
  }
}
