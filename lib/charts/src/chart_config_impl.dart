//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class DefaultChartConfigImpl extends Observable implements ChartConfig {
  final Map<String, ChartAxisConfig> _measureAxisRegistry = {};
  final Map<int, ChartAxisConfig> _dimensionAxisRegistry = {};
  final SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  bool _isRTL = false;
  Iterable<ChartSeries> _series;
  Iterable<int> _dimensions;
  StreamSubscription _dimensionsSubscription;

  @override
  Rect minimumSize = const Rect.size(400, 300);

  @override
  bool isLeftAxisPrimary = false;

  @override
  bool autoResizeAxis = true;

  @override
  ChartLegend legend;

  @override
  Iterable<String> displayedMeasureAxes;

  @override
  bool renderDimensionAxes = true;

  @override
  bool switchAxesForRTL = true;

  DefaultChartConfigImpl(
      Iterable<ChartSeries> series, Iterable<int> dimensions) {
    this.series = series;
    this.dimensions = dimensions;
  }

  @override
  set series(Iterable<ChartSeries> values) {
    assert(values != null && values.isNotEmpty);

    _disposer.dispose();
    _series = values;
    notifyChange(const ChartConfigChangeRecord());

    // Monitor each series for changes on them
    values.forEach((item) {
      if (item is Observable) {
        _disposer.add(
            (item as Observable)
                .changes
                .listen((_) => notifyChange(const ChartConfigChangeRecord())),
            item);
      }
    });

    // Monitor series for changes.  When the list changes, update
    // subscriptions to ChartSeries changes.
    if (_series is ObservableList) {
      var observable = _series as ObservableList;
      _disposer.add(observable.listChanges.listen((records) {
        records.forEach((record) {
          record.removed.forEach((value) => _disposer.unsubscribe(value));
          for (int i = 0; i < record.addedCount; i++) {
            var added = observable[i + record.index];
            _disposer.add(added.changes
                .listen((_) => notifyChange(const ChartConfigChangeRecord())));
          }
        });
        notifyChange(const ChartConfigChangeRecord());
      }));
    }
  }

  @override
  Iterable<ChartSeries> get series => _series;

  @override
  set dimensions(Iterable<int> values) {
    _dimensions = values;

    if (_dimensionsSubscription != null) {
      _dimensionsSubscription.cancel();
      _dimensionsSubscription = null;
    }

    if (values == null || values.isEmpty) return;

    if (_dimensions is ObservableList) {
      _dimensionsSubscription = (_dimensions as ObservableList)
          .listChanges
          .listen((_) => notifyChange(const ChartConfigChangeRecord()));
    }
  }

  @override
  Iterable<int> get dimensions => _dimensions;

  @override
  void registerMeasureAxis(String id, ChartAxisConfig config) {
    assert(config != null);
    _measureAxisRegistry[id] = config;
    notifyChange(const ChartConfigChangeRecord());
  }

  @override
  ChartAxisConfig getMeasureAxis(String id) => _measureAxisRegistry[id];

  @override
  void registerDimensionAxis(int column, ChartAxisConfig config) {
    assert(config != null);
    assert(dimensions.contains(column));
    _dimensionAxisRegistry[column] = config;
    notifyChange(const ChartConfigChangeRecord());
  }

  @override
  ChartAxisConfig getDimensionAxis(int column) =>
      _dimensionAxisRegistry[column];

  @override
  set isRTL(bool value) {
    if (_isRTL != value && value != null) {
      _isRTL = value;
      notifyChange(const ChartConfigChangeRecord());
    }
  }

  @override
  bool get isRTL => _isRTL;
}
