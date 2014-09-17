/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

abstract class ChartAreaEventSource {
  /**
   * Stream of events that notify when a mouse button was pressed anywhere
   * on the [ChartArea]
   */
  Stream<ChartEvent> get onMouseUp;

  /**
   * Stream of events that notify when an already pressed mouse button is
   * released on the [ChartArea]
   */
  Stream<ChartEvent> get onMouseDown;

  /**
   * Stream of events that notify when mouse pointer enters [ChartArea]
   */
  Stream<ChartEvent> get onMouseOver;

  /**
   * Stream of events that notify when mouse pointer exits [ChartArea]
   */
  Stream<ChartEvent> get onMouseOut;

  /**
   * Stream of events that notify when mouse is moved on [ChartArea]
   */
  Stream<ChartEvent> get onMouseMove;

  /**
   * Stream of events that notify when a rendered value is clicked.
   */
  Stream<ChartEvent> get onValueClick;

  /**
   * Stream of events that notify when user moves mouse over a rendered value
   */
  Stream<ChartEvent> get onValueMouseOver;

  /**
   * Stream of events that notify when user moves mouse out of rendered value
   */
  Stream<ChartEvent> get onValueMouseOut;
}

/**
 * Class representing an event emitted by ChartEventSource
 */
abstract class ChartEvent {
  /** DOM source event that caused this event */
  Event get source;

  /** ChartSeries if any on which this event occurred */
  ChartSeries get series;

  /** Column in ChartData on which this event occurred */
  int get column;

  /** Row in ChartData on which this event occurred */
  int get row;

  /** Value from ChartData on which the event occurred */
  num get value;

  /** X position relative to the rendered chart */
  num get chartX;

  /** Y position relative to the rendered chart */
  num get chartY;
}

/**
 * Interface implemented by chart behaviors.
 * During initialization, the behaviors subscribe to any necessary events and
 * handle them appropriately.
 */
abstract class ChartBehavior {
  void init(ChartArea area, Element upperRenderPane, Element lowerRenderPane);
}
