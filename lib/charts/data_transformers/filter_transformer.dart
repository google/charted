//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

typedef bool FilterFunction(dynamic value);

/// Transforms the ChartData base on the specified FilterDefinitions.  Each row
/// of data will be tested by passing the value at target column to the filter
/// function.  If filter function returns false, the row will be filtered out.
/// This transformer does not modify the column part of the input ChartData.
class FilterTransformer extends Observable
    implements ChartDataTransform, ChartData {
  final SubscriptionsDisposer _dataSubscriptions = new SubscriptionsDisposer();
  List<ChartColumnSpec> columns;
  ObservableList<List> rows = new ObservableList();
  List<FilterDefinition> filterFunctions;
  ChartData _data;

  FilterTransformer(this.filterFunctions);

  /// Transforms the input data with the list of [FilterDefinition] specified in
  /// the constructor.  If the rows and columns are ObservableList in the data,
  /// changes in rows and columns in input data will trigger transform to be
  /// performed again to update the output rows and columns.
  ChartData transform(ChartData data) {
    _data = data;
    _registerListeners();
    _transform();
    return this;
  }

  /// Registers listeners if data.rows or data.columns are Observable.
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

  /// Performs the filter transform with _data.  This is called on transform and
  /// onChange if the input ChartData is Observable.
  _transform() {
    columns = _data.columns;
    rows.clear();

    for (var row in _data.rows) {
      // Add the row if each value in target column passes the filter function.
      if (filterFunctions
          .every((e) => e.filterFunc(row.elementAt(e.targetColumn)))) {
        rows.add(row);
      }
    }
  }
}

class FilterDefinition {
  final FilterFunction filterFunc;
  final int targetColumn;
  FilterDefinition(this.targetColumn, this.filterFunc);
}
