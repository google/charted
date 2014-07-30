/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartSeries implements ChartSeries {
  final String name;

  Iterable<String> _measureAxisIds;
  Iterable<int> _measures;

  StreamController _controller;
  ChartRenderer _renderer;

  SubscriptionsDisposer _disposer = new SubscriptionsDisposer();

  _ChartSeries(this.name, Iterable<int> measures, this._renderer,
      Iterable<String> measureAxisIds) {
    this.measures = measures;
    this.measureAxisIds = measureAxisIds;
  }

  set renderer(ChartRenderer value) {
    if (value != null && value == _renderer) return;
    _renderer.clear();
    _renderer = value;
    _controller.add(this);
  }

  ChartRenderer get renderer => _renderer;

  set measures(Iterable<int> value) {
    _measures = value;

    if (_measures is ObservableList) {
      _disposer.add(
          (_measures as ObservableList).listChanges.listen(_measuresChanged));
    }
  }

  Iterable<int> get measures => _measures;

  set measureAxisIds(Iterable<String> value) => _measureAxisIds = value;
  Iterable<String> get measureAxisIds => _measureAxisIds;

  _measuresChanged(List<ListChangeRecord> changes) {
      if (_measures is! ObservableList) return;

      changes.forEach((ListChangeRecord change) {
        _controller.add(change);
      });
    }

  Stream<ChartSeries> get changes {
    if (_controller == null)
      _controller = new StreamController(sync:true);
    return _controller.stream;
  }
}
