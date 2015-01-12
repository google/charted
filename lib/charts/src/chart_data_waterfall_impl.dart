/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _WaterfallChartData extends _ChartData implements WaterfallChartData {
  Iterable<int> _baseRows;

  // The last row should always be base (no shifting on y-axis). If not,
  // calculate the sum since last base, and store them in these tables.
  List<int> _extendedBaseRows;
  List<List> _extendedRows;
  bool _extended = false;

  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  _WaterfallChartData(Iterable<ChartColumnSpec> columns,
       Iterable<Iterable> rows, [Iterable<int> baseRows])
       : super(columns, rows) {
    // Force calling setter.
    this.baseRows = baseRows;
  }

  @override
  set rows(Iterable<Iterable> value) {
    super.rows = value;
    _extendRowsOrNot();
  }

  @override
  Iterable<Iterable> get rows => _extended ? _extendedRows : _rows;

  set baseRows(Iterable<int> value) {
    _baseRows = value == null? new ObservableList() : value;

    if (_baseRows is ObservableList) {
      _disposer.add(
          (_baseRows as ObservableList).listChanges.listen(_baseRowsChanged));
    }

    _extendRowsOrNot();
  }

  Iterable<int> get baseRows => _extended ? _extendedBaseRows : _baseRows;

  @override
  rowsChanged(List<ListChangeRecord> changes) {
    super.rowsChanged(changes);
    _extendRowsOrNot();
  }

  _baseRowsChanged(List<ListChangeRecord> changes) {
    if (_baseRows is! ObservableList) return;
    _extendRowsOrNot();
    // force re-draw?
    notifyChange(new ChartRowChangeRecord(changes));
  }

  /*
   * If [_baseRows] does not specify last row as base row, add one more row
   * as the running totals of measures since last base row.
   */
  _extendRowsOrNot() {
    _extended = false;
    if (_baseRows == null || _rows == null || _rows.length < 2) return;

    if (!_baseRows.contains(_rows.length - 1)) {
      _fillExtendRows();
      _extended = true;
    }
  }

  /*
   * Set [_extendedRows] and [_extendedBaseRows] to include the computed
   * last row with running totals of measures since last base row, which
   * will be shown as base row.
   */
  _fillExtendRows() {
    var start = 0;
    _baseRows.forEach((index) => start = index > start? index : start);

    var runningTotal = new List.from(_rows.elementAt(start));
    for (int i = start + 1; i < _rows.length; i++) {
      for (int j = 1 /* skip label */; j < _rows.elementAt(i).length; j++) {
        runningTotal[j] += _rows.elementAt(i).elementAt(j);
      }
    }
    runningTotal[0] = 'Total';

    _extendedRows = new List.from(_rows)
      ..add(runningTotal);
    _extendedBaseRows = new List.from(_baseRows)
      ..add(_extendedRows.length - 1);
  }
}
