/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.selection.transition;

// handle transitions on an element-basis, so we can cancel if another is
// scheduled
Map<Element, int> _transitionMap = {};

class _TransitionImpl implements Transition {
  SelectionCallback _delay = (d, i, c) => 0;
  SelectionCallback _duration =
      (d, i, c) => Transition.defaultDurationMilliseconds;
  Selection _selection;
  Map _attrs = {};
  Map _styles = {};
  Map _attrTweens = {};
  Map _styleTweens = {};
  Map<AnimationTimer, Element> _timerMap = {};
  Map<Element, List<Interpolator>> _attrMap = {};
  Map<Element, int> _durationMap = {};
  bool _interrupted = false;
  bool _remove = false;
  var _timerDelay = 0;

  _TransitionImpl(this._selection, [num delay = 0]) {
    _transitionNode(delay);
    _timerDelay = delay;
  }

  Interpolator ease =
      clampEasingFn(Transition.defaultEasingMode(Transition.defaultEasingType));

  void delay(int millisecond) {
    delayWithCallback(toCallback(millisecond));
  }

  void delayWithCallback(SelectionCallback fn) {
    _delay = fn;
  }

  void duration(int millisecond) {
    durationWithCallback(toCallback(millisecond));
  }

  void durationWithCallback(SelectionCallback fn) {
    _duration = fn;
  }

  void attr(String name, val) {
    attrWithCallback(name, toCallback(val));
  }

  void attrWithCallback(String name, SelectionCallback fn) {
    _attrs[name] = fn;
  }

  void attrTween(String name, AttrTweenCallback tween) {
    _attrTweens[name] = tween;
  }

  void style(String property, String val, [String priority = '']) {
    styleWithCallback(property, toCallback(val), priority);
  }

  void styleWithCallback(String property, SelectionCallback<String> fn,
      [String priority = '']) {
    _styles[property] = {'callback': fn, 'priority': priority};
  }

  void styleTween(String property, StyleTweenCallback tween,
      [String priority]) {
    _styleTweens[property] = {'callback': tween, 'priority': priority};
  }

  // Starts a timer that registers all attributes, durations, and delays for the
  // transition of the current selection.
  _transitionNode(num delay) {
    new AnimationTimer((elapsed) {
      _selection.each((d, i, c) {
        var tweenList = <Interpolator>[];
        _attrs.forEach((key, value) {
          tweenList.add(_getAttrInterpolator(c, key, value(d, i, c)));
        });
        _attrTweens.forEach((key, value) {
          tweenList.add(
              (t) => c.setAttribute(key, value(d, i, c.getAttribute(key))(t)));
        });
        _styles.forEach((key, value) {
          tweenList.add(_getStyleInterpolator(
              c, key, value['callback'](d, i, c), value['priority']));
        });
        _styleTweens.forEach((key, value) {
          tweenList.add((t) => c.style.setProperty(
              key,
              value['callback'](d, i, c.style.getPropertyValue(key))(t)
                  .toString(),
              value['priority']));
        });

        _attrMap[c] = tweenList;
        _durationMap[c] = _duration(d, i, c);
        _timerMap[new AnimationTimer(_tick, delay: _delay(d, i, c))] = c;

        if (!_transitionMap.containsKey(c)) {
          _transitionMap[c] = 1;
        } else {
          _transitionMap[c]++;
        }
      });
      return true;
    }, delay: delay);
  }

  // Returns the correct interpolator function for the old and new attribute.
  Interpolator _getAttrInterpolator(
      Element element, String attrName, newValue) {
    var attr = element.attributes[attrName];
    var interpolator = createStringInterpolator(attr, newValue.toString());
    return (t) => element.setAttribute(attrName, interpolator(t).toString());
  }

  // Returns the correct interpolator function for the old and new style.
  Interpolator _getStyleInterpolator(
      Element element, String styleName, newValue, priority) {
    var style = element.style.getPropertyValue(styleName);

    var interpolator = createStringInterpolator(style, newValue.toString());

    return (t) => element.style
        .setProperty(styleName, interpolator(t).toString(), priority);
  }

  // Ticks of the transition, this is the callback registered to the
  // ChartedTimer, called on each animation frame until the transition duration
  // has been reached.
  bool _tick(int elapsed) {
    if (_interrupted) {
      return true;
    }
    var activeNode = _timerMap[AnimationTimer.active];
    var t = elapsed / _durationMap[activeNode];
    for (Interpolator tween in _attrMap[activeNode]) {
      tween(ease(t));
    }

    if (t >= 1) {
      if (_remove && _transitionMap[activeNode] == 1) {
        activeNode.remove();
      }

      if (_transitionMap[activeNode] > 1) {
        _transitionMap[activeNode]--;
      } else {
        _transitionMap.remove(activeNode);
      }

      return true;
    }

    return false;
  }

  // Interrupts the transition.
  void interrupt() {
    _interrupted = true;
  }

  Transition select(String selector) {
    var t = new Transition(_selection.select(selector));
    t.ease = ease;
    t.delayWithCallback(_delay);
    t.durationWithCallback(_duration);
    return t;
  }

  Transition selectAll(String selector) {
    var t = new Transition(_selection.selectAll(selector));
    t.ease = ease;
    t.delayWithCallback(_delay);
    t.durationWithCallback(_duration);
    return t;
  }

  Transition transition() {
    var e = _selection.first;
    var delay = _delay(_selection.scope.datum(e), 0, e) +
        _duration(_selection.scope.datum(e), 0, e) +
        _timerDelay;
    var t = new _TransitionImpl(_selection, delay);
    t.ease = ease;
    t.durationWithCallback(_duration);
    return t;
  }

  void remove() {
    _remove = true;
  }
}
