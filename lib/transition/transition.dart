/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
library charted.transition;

import "dart:html" show Element,document;
import "package:charted/core/core.dart";
import "package:charted/event/event.dart";
import "package:charted/selection/selection.dart";
import "package:charted/interpolators/interpolators.dart";

part "transition_impl.dart";

typedef InterpolateFn AttrTweenCallback(datum, int ei, String attr);
typedef InterpolateFn StyleTweenCallback(datum, int ei, String style);

/**
 * Transitions are created using the transition operator on a selection.
 * Transitions start automatically upon creation after a delay which defaults
 * to zero; however, note that a zero-delay transition actually starts after a
 * minimal (~17ms) delay, pending the first timer callback.
 * Transitions have a default duration of 250ms.
 */
abstract class Transition {

  /** A settable default easing type */
  static EasingFn defaultEasingType = easeCubic();

  /** A settable default easing mode */
  static EasingMode defaultEasingMode = reflectEasingFn;

  /** A settable default transition duration */
  static int defaultDuration = 250;

  /** Sets the ease function of the transition, default is cubic-in-out. */
  InterpolateFn ease;

  /**
   * Specifies the transition delay in milliseconds. All elements are given the
   * same delay. The default delay is 0.
   */
  void delay(int millisecond);

  /**
   * Sets the delay with a ChartedCallback function which would be evaluated for
   * each selected element (in order), being passed the current datum d, the
   * current index i, and the current DOM element. The function's return value
   * is then used to set each element's delay.
   */
  void delayWithCallback(SelectionCallback fn);

  /**
   * Specifies per-element duration in milliseconds. All elements are given the
   * same duration in millisecond.  The default duration is 250ms.
   */
  void duration(int millisecond);

  /**
   * Sets the duration with a ChartedCallback which would be evaluated for each
   * selected element (in order), being passed the current datum d, the current
   * index i, and the current DOM element.  The function's return value is then
   * used to set each element's duration.
   */
  void durationWithCallback(SelectionCallback fn);

  /**
   * Sets the attribute [name] on all elements when [val] is not null.
   * Removes the attribute when [val] is null.
   */
  void attr(String name, val);

  /**
   * Same as [attr], but calls [fn] for each non-null element in
   * the selection (with data associated to the element, index of the
   * element in it's group and the element itself) to get the value
   * of the attribute.
   */
  void attrWithCallback(String name, SelectionCallback fn);

  /**
   * Transitions the value of the attribute with the specified name according to
   * the specified tween function. The starting and ending value of the
   * transition are determined by tween; the tween function is invoked when the
   * transition starts on each element, being passed the current datum d, the
   * current index i and the current attribute value a. The return value of
   * tween must be an interpolator: a function that maps a parametric value t in
   * the domain [0,1] to a color, number or arbitrary value.
   */
  void attrTween(String name, AttrTweenCallback tween);

  /**
   * Transitions the value of the CSS style property with the specified name to
   * the specified value. An optional priority may also be specified, either as
   * null or the string "important" (without the exclamation point). The
   * starting value of the transition is the current computed style property
   * value, and the ending value is the specified value. All elements are
   * transitioned to the same style property value.
   */
  void style(String property, String val, [String priority]);

  /**
   * Transitions the style with a CartedCallback which would be evaluated for
   * each selected element (in order), being passed the current datum d and the
   * current index i, and the current DOM element.
   * The function's return value is then used to transition each element's
   * style property.
   */
  void styleWithCallback(String property,
      SelectionCallback<String> fn, [String priority]);

  /**
   * Transitions the value of the CSS style property with the specified name
   * according to the specified tween function. An optional priority may also
   * be specified, either as null or the string "important" (without the
   * exclamation point). The starting and ending value of the transition are
   * determined by tween; the tween function is invoked when the transition
   * starts on each element, being passed the current datum d, the current index
   * i and the current attribute value a. The return value of tween must be an
   * interpolator: a function that maps a parametric value t in the domain [0,1]
   * to a color, number or arbitrary value.
   */
  void styleTween(String property, StyleTweenCallback tween, [String priority]);

  /** Interrupts the transition. */
  void interrupt();

  /**
   * For each element in the current transition, selects the first descendant
   * element that matches the specified selector string. If no element matches
   * the specified selector for the current element, the element at the current
   * index will be null in the returned selection; operators (with the exception
   * of data) automatically skip null elements, thereby preserving the index of
   * the existing selection. If the current element has associated data, this
   * data is inherited by the returned subselection, and automatically bound to
   * the newly selected elements. If multiple elements match the selector, only
   * the first matching element in document traversal order will be selected.
   */
  Transition select(String selector);

  /**
   * For each element in the current transition, selects descendant elements
   * that match the specified selector string. The returned selection is grouped
   * by the ancestor node in the current selection. If no element matches the
   * specified selector for the current element, the group at the current index
   * will be empty in the returned selection. The subselection does not inherit
   * data from the current selection; however, if data was previously bound to
   * the selected elements, that data will be available to operators.
   */
  Transition selectAll(String selector);

  /**
   * Creates a new transition on the same selected elements that starts with
   * this transition ends. The new transition inherits this transition’s
   * duration and easing. This can be used to define chained transitions without
   * needing to listen for "end" events.  Only works when parent delay and
   * duration are constant.
   */
  Transition transition();

  /** Factory method to create an instance of the default implementation */
  factory Transition(Selection selection) => new _TransitionImpl(selection);
}