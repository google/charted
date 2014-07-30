/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartData implements ChartData, ChartDataObservable {
  Iterable<ChartColumnSpec> _columns;
  Iterable<Iterable> _rows;

  StreamController _valuesChangeController;
  StreamController _rowsChangeController;

  bool _hasObservableRows = false;

  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  _ChartData(Iterable<ChartColumnSpec> columns, Iterable<Iterable> rows) {
    this.columns = columns;
    this.rows = rows;
  }

  set columns(Iterable<ChartColumnSpec> value) {
    assert(value != null && value.isNotEmpty);

    // Create a copy of columns.  We do not currently support
    // changes to the list of columns.  Any changes to the spec
    // will be applied at the next ChartBase.draw();
    this._columns = new List.from(value);
  }

  Iterable<ChartColumnSpec> get columns => _columns;

  set rows(Iterable<Iterable> value) {
    assert(value != null);

    _rows = value;
    if (_rows is ObservableList) {
      _disposer.add(
          (_rows as ObservableList).listChanges.listen(_rowsChanged));
    }

    if (_rows.every((row) => row is ObservableList)) {
      _hasObservableRows = true;
      for (int i = 0; i < _rows.length; i++) {
        var row = _rows.elementAt(i);
        _disposer.add(row.listChanges.listen((changes)
            => _valuesChanged(i, changes)), row);
      };
    } else if (_rows is Observable) {
      logger.info('List of rows is Observable, but not rows themselves!');
    }
  }

  Iterable<Iterable> get rows => _rows;

  _rowsChanged(List<ListChangeRecord> changes) {
    if (_rows is! ObservableList || _rowsChangeController == null) return;

    changes.forEach((ListChangeRecord change) {
      _rowsChangeController.add(change);

      if (!_hasObservableRows) return;
      change.removed.forEach((item) => _disposer.unsubscribe(item));

      for(int i = 0; i < change.addedCount; i++) {
        var index = change.index + i,
            row = _rows.elementAt(index);

        if (row is! ObservableList) {
          logger.severe('A non-observable row was added! '
              'Changes on this row will not be monitored');
        } else {
          _disposer.add(row.listChanges.listen((changes)
              => _valuesChanged(index, changes)), row);
        }
      }
    });
  }

  _valuesChanged(int index, List<ListChangeRecord> changes) {
    if (!_hasObservableRows) return;
    if (_valuesChangeController != null)
      changes.forEach((change) => _valuesChangeController.add(
          new ChartedPair(index, change)));
  }

  Stream<ChartedPair> get onValuesUpdated {
    if (_valuesChangeController == null)
      _valuesChangeController = new StreamController.broadcast(sync:true);
    return _valuesChangeController.stream;
  }

  Stream<ListChangeRecord> get onRowsChanged {
    if (_rowsChangeController == null)
      _rowsChangeController = new StreamController.broadcast(sync:true);
    return _rowsChangeController.stream;
  }
}
