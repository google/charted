//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.utils;

class SubscriptionsDisposer {
  List<StreamSubscription> _subscriptions = [];
  Expando<StreamSubscription> _byObject = new Expando();

  void add(StreamSubscription value, [Object handle]) {
    if (handle != null) _byObject[handle] = value;
    _subscriptions.add(value);
  }

  void addAll(Iterable<StreamSubscription> values, [Object handle]) {
    for (var subscription in values) {
      add(subscription, handle);
    }
  }

  void unsubscribe(Object handle) {
    StreamSubscription s = _byObject[handle];
    if (s != null) {
      _subscriptions.remove(s);
      s.cancel();
    }
  }

  void dispose() {
    _subscriptions.forEach((StreamSubscription val) {
      if (val != null) val.cancel();
    });
    _subscriptions = [];
  }
}
