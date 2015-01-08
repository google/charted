/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartData extends ChangeNotifier implements ChartData {
  Iterable<ChartColumnSpec> _columns;
  Iterable<Iterable> _rows;

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
          (_rows as ObservableList).listChanges.listen(rowsChanged));
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

  rowsChanged(List<ListChangeRecord> changes) {
    if (_rows is! ObservableList) return;
    notifyChange(new ChartRowChangeRecord(changes));

    if (!_hasObservableRows) return;
    changes.forEach((ListChangeRecord change) {
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
    notifyChange(new ChartValueChangeRecord(index, changes));
  }
}
