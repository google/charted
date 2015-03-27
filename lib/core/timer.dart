//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// A window.requestAnimationFrame based timer for use with transitions
library charted.core.timer;

import 'dart:async';
import 'dart:html' show window;
import 'dart:collection';

class AnimationTimer {
  static DoubleLinkedQueue<DoubleLinkedQueueEntry<AnimationTimer>>
      _timerQueue =
          new DoubleLinkedQueue<DoubleLinkedQueueEntry<AnimationTimer>>();

  static bool _interval = false;
  static Timer _timer;
  static var activeTimer;

  Function _callback;
  num _time;
  bool _finished = false;

  /**
   * Start a custom animation timer, invoking the specified function
   * repeatedly until it returns true. There is no way to cancel the timer
   * after it starts, so make sure your timer function returns true when done!
   *
   * An optional numeric delay in milliseconds may be specified when the given
   * function should only be invoked after a delay. The delay is relative to
   * the specified time in milliseconds since UNIX epoch; if time is not
   * specified, it defaults to Date.now
   */
  AnimationTimer(this._callback, [int delay = 0, DateTime then = null]) {
    if (then == null) {
      then = new DateTime.now();
    }
    _time = then.add(new Duration(milliseconds: delay)).millisecondsSinceEpoch;
    _timerQueue.add(new DoubleLinkedQueueEntry(this));

    if (!_interval) {
      if (_timer != null) {
        _timer.cancel();
      }
      _interval = true;
      window.animationFrame.then(_step);
    }
  }

  /**
   * Immediately execute (invoke once) any active timers. Normally, zero-delay
   * transitions are executed after an instantaneous delay (<10ms). This can
   * cause a brief flicker if the browser renders the page twice: once at the
   * end of the first event loop, then again immediately on the first timer
   * callback. By flushing the timer queue at the end of the first event loop,
   * you can run any zero-delay transitions immediately and avoid the flicker.
   */
  void flush() {
    _mark();
    _sweep();
  }

  /**
   * Interates through each of the timer and execute the callback if the set
   * delay has elasped.
   */
  _mark() {
    var now = new DateTime.now().millisecondsSinceEpoch;
    for (DoubleLinkedQueueEntry e in _timerQueue) {
      if (now > e.element._time) {
        activeTimer = e.element;
        e.element._finished = e.element._callback(now - e.element._time);
      }
    }
    return now;
  }

  /**
   * Flush after callbacks to avoid concurrent queue modification.
   * Removes all finished timer from the queue and returns the time of the
   * earliest active timer, post-sweep.
   */
  _sweep() {
    var time = double.INFINITY;
    for (DoubleLinkedQueueEntry e in _timerQueue) {
      if (e.element._finished) {
        _timerQueue.remove(e);
      } else {
        if (e.element._time < time) {
          time = e.element._time;
        }
      }
    }
    return time;
  }

  /*
   * If the delay of the timer in the nearest future is less than 24ms, use
   * animationFrame to step, otherwise schedule the step of the chart timer
   * using a Dart Timer with the delay.
   */
  _step([num delta = 0]) {
    var now = _mark(),
        delay = _sweep() - now;

    if (delay > 24) {
      // If delay is infinity there's no more timer in queue.
      if (delay.isFinite) {
        if (_timer != null) {
          _timer.cancel();
        }
        _timer = new Timer(new Duration(milliseconds: delay), _step);
      }
      _interval = false;
      activeTimer = null;
    }
    else {
      _interval = true;
      window.animationFrame.then(_step);
    }
  }
}

