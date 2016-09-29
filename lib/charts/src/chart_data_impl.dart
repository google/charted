//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class DefaultChartDataImpl extends Observable implements ChartData {
  List<ChartColumnSpec> _columns;
  List<List> _rows;

  bool _hasObservableRows = false;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  DefaultChartDataImpl(
      Iterable<ChartColumnSpec> columns, Iterable<Iterable> rows) {
    this.columns = new List<ChartColumnSpec>.from(columns);
    var rowsList = new List.from(rows);
    this.rows = new List<List>.generate(
        rowsList.length, (i) => new List.from(rowsList[i]));
  }

  set columns(Iterable<ChartColumnSpec> value) {
    assert(value != null);

    // Create a copy of columns.  We do not currently support
    // changes to the list of columns.  Any changes to the spec
    // will be applied at the next ChartBase.draw();
    this._columns = new List<ChartColumnSpec>.from(value);
  }

  List<ChartColumnSpec> get columns => _columns;

  set rows(List<List> value) {
    assert(value != null);

    _rows = value;
    if (_rows is ObservableList) {
      _disposer.add((_rows as ObservableList).listChanges.listen(rowsChanged));
    }

    if (_rows.every((row) => row is ObservableList)) {
      _hasObservableRows = true;
      for (int i = 0; i < _rows.length; i++) {
        var row = _rows.elementAt(i);
        _disposer.add(
            (row as ObservableList)
                .listChanges
                .listen((changes) => _valuesChanged(i, changes)),
            row);
      }
      ;
    } else if (_rows is Observable) {
      logger.info('List of rows is Observable, but not rows themselves!');
    }
  }

  List<List> get rows => _rows;

  rowsChanged(List<ListChangeRecord> changes) {
    if (_rows is! ObservableList) return;
    notifyChange(new ChartRowChangeRecord(changes));

    if (!_hasObservableRows) return;
    changes.forEach((ListChangeRecord change) {
      change.removed.forEach((item) => _disposer.unsubscribe(item));

      for (int i = 0; i < change.addedCount; i++) {
        var index = change.index + i, row = _rows.elementAt(index);

        if (row is! ObservableList) {
          logger.severe('A non-observable row was added! '
              'Changes on this row will not be monitored');
        } else {
          _disposer.add(
              (row as ObservableList).listChanges
                  .listen((changes) => _valuesChanged(index, changes)),
              row);
        }
      }
    });
  }

  _valuesChanged(int index, List<ListChangeRecord> changes) {
    if (!_hasObservableRows) return;
    notifyChange(new ChartValueChangeRecord(index, changes));
  }

  @override
  String toString() {
    var cellDataLength = new List.filled(rows.elementAt(0).length, 0);
    for (var i = 0; i < columns.length; i++) {
      if (cellDataLength[i] < columns.elementAt(i).label.toString().length) {
        cellDataLength[i] = columns.elementAt(i).label.toString().length;
      }
    }
    for (var row in rows) {
      for (var i = 0; i < row.length; i++) {
        if (cellDataLength[i] < row.elementAt(i).toString().length) {
          cellDataLength[i] = row.elementAt(i).toString().length;
        }
      }
    }

    var totalLength = 1; // 1 for the leading '|'.
    for (var length in cellDataLength) {
      // 3 for the leading and trailing ' ' padding and trailing '|'.
      totalLength += length + 3;
    }

    // Second pass for building the string buffer and pad each cell with space
    // according to the difference between cell string length and max length.
    var strBuffer = new StringBuffer();
    strBuffer.write('-' * totalLength + '\n');
    strBuffer.write('|');

    // Process columns.
    for (var i = 0; i < columns.length; i++) {
      var label = columns.elementAt(i).label;
      var lengthDiff = cellDataLength[i] - label.length;
      strBuffer.write(' ' * lengthDiff + ' ${label} |');
    }
    strBuffer.write('\n' + '-' * totalLength + '\n');

    // Process rows.
    for (var row in rows) {
      strBuffer.write('|');
      for (var i = 0; i < row.length; i++) {
        var data = row.elementAt(i).toString();
        var lengthDiff = cellDataLength[i] - data.length;
        strBuffer.write(' ' * lengthDiff + ' ${data} |');

        if (i == row.length - 1) {
          strBuffer.write('\n' + '-' * totalLength + '\n');
        }
      }
    }
    return strBuffer.toString();
  }
}
