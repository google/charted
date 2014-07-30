/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartConfig implements ChartConfig {
  Iterable<ChartSeries> _series;
  Iterable<int> _dimensions;
  Iterable<int> _dimensionTickNumbers;

  StreamController _controller;
  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();
  final Map<ChartSeries,StreamSubscription> _seriesChangeListeners = {};

  StreamSubscription _seriesSubscription;
  StreamSubscription _dimensionsSubscription;

  int width;
  int height;
  int xAxisHeight = 50;
  int yAxisWidth = 50;
  bool isRotated = false;

  ChartLegend legend;

  _ChartConfig(Iterable<ChartSeries> series, Iterable<int> dimensions,
      {Iterable<int> dimensionTickNumbers}) {
    this.series = series;
    this.dimensions = dimensions;
    this.dimensionTickNumbers = dimensionTickNumbers;
  }

  set series(Iterable<ChartSeries> values) {
    assert(values != null && values.isNotEmpty);

    _disposer.dispose();
    _series = values;
    _change();

    // Monitor each series for changes on them
    values.forEach((item) =>
        _disposer.add(item.changes.listen((_) => _change()), item));

    // Monitor series for changes.  When the list changes, update
    // subscriptions to ChartSeries changes.
    if (_series is ObservableList) {
      var observable = _series as ObservableList;
      _disposer.add(observable.listChanges.listen((records) {
        records.forEach((record) {
          record.removed.forEach((value) => _disposer.unsubscribe(value));
          for (int i = 0; i < record.addedCount; i++) {
            var added = observable[i + record.index];
            _disposer.add(added.changes.listen((_) => _change()), added);
          }
        });
        _change();
      }));
    }
  }

  List<ChartSeries> get series => _series;

  set dimensions(Iterable<int> values) {
    _dimensions = values;

    if (_dimensionsSubscription != null) {
      _dimensionsSubscription.cancel();
      _dimensionsSubscription = null;
    }

    if (values == null || values.isEmpty) return;

    if (_dimensions is ObservableList) {
      _dimensionsSubscription =
          (_dimensions as ObservableList).listChanges.listen((_) => _change());
    }
  }

  List<int> get dimensions => _dimensions;

  set dimensionTickNumbers(Iterable<int> values) {
    _dimensionTickNumbers = values;
  }

  List<int> get dimensionTickNumbers => _dimensionTickNumbers;

  _change() {
    if (_controller != null) _controller.add(this);
  }

  Stream get changes {
    if (_controller == null) {
      _controller = new StreamController(sync:true);
    }
    return _controller.stream;
  }
}
