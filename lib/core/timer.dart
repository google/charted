//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// A [window.requestAnimationFrame] based timer for use with transitions.
/// Uses [dart.async.Timer] when the time until next timeout is too long.
library charted.core.timer;

import 'dart:async';
import 'dart:html' show window;
import 'dart:collection';

typedef bool TimerCallback(int time);

class AnimationTimer extends LinkedListEntry<AnimationTimer> {
  static LinkedList<AnimationTimer> _queue = new LinkedList<AnimationTimer>();

  /// true if we are already waiting for window.animationFrame. At any given
  /// time, only one of _timerScheduled and _animationFrameRequested are set
  static bool _animationFrameRequested = false;

  /// Instance of currently scheduled timer. At any given time, only one
  /// of _timerScheduled and _animationFrameRequested are set.
  static Timer _timerScheduled;

  /// Currently active timer.
  static AnimationTimer active;

  /// Callback function that is called when the timer is fired.
  final TimerCallback callback;

  /// Start time of the animation.
  final int time;

  /// Schedule a new [callback] to be called [delay] micro-seconds after
  /// [then] micro-seconds since epoch.
  AnimationTimer(this.callback, {int delay: 0, int then: null})
      : time = then == null
            ? new DateTime.now().millisecondsSinceEpoch + delay
            : then + delay {
    _queue.add(this);
    if (!_animationFrameRequested) {
      if (_timerScheduled != null) {
        _timerScheduled.cancel();
      }
      _animationFrameRequested = true;
      window.animationFrame.then(_step);
    }
  }

  /// Iterate through all timers, call the callbacks where necessary and
  /// return milliseconds until next timer.
  static int flush() {
    int now = new DateTime.now().millisecondsSinceEpoch;
    int earliest = null;
    AnimationTimer timer = _queue.isEmpty ? null : _queue.first;

    while (timer != null) {
      bool finished = false;
      AnimationTimer ref = timer;

      if (now > timer.time) {
        active = timer;
        finished = timer.callback(now - timer.time);
      }
      if (!finished && (earliest == null || timer.time < earliest)) {
        earliest = timer.time;
      }
      timer = timer.next;
      if (finished) ref.unlink();
    }
    active = null;
    return earliest == null ? earliest : earliest - now;
  }

  /// Internal timer and animation frame handler.
  _step([num _]) {
    int delay = flush();

    if (delay == null) {
      _animationFrameRequested = false;
    } else if (delay > 24) {
      if (_timerScheduled != null) {
        _timerScheduled.cancel();
      }
      _timerScheduled = new Timer(new Duration(milliseconds: delay), _step);
      _animationFrameRequested = false;
    } else {
      _animationFrameRequested = true;
      window.animationFrame.then(_step);
    }
  }
}
