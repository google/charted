//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Interface implemented by a [CartesianRenderer] that supports behaviors.
///
abstract class ChartRendererBehaviorSource {
  /// Stream to notify when a rendered value is clicked.
  Stream<ChartEvent> get onValueClick;

  /// Stream to notify when user moves mouse over a rendered value
  Stream<ChartEvent> get onValueMouseOver;

  /// Stream to notify when user moves mouse out of rendered value
  Stream<ChartEvent> get onValueMouseOut;
}

///
/// Interface implemented by a [ChartArea] that supports behaviors.
///
abstract class ChartAreaBehaviorSource implements ChartRendererBehaviorSource {
  /// Stream to notify when a mouse button is pressed on [ChartArea].
  Stream<ChartEvent> get onMouseDown;

  /// Stream to notify when a pressed mouse button is released on [ChartArea].
  Stream<ChartEvent> get onMouseUp;

  /// Stream to notify when mouse pointer enters [ChartArea].
  Stream<ChartEvent> get onMouseOver;

  /// Stream to notify when mouse pointer leaves [ChartArea].
  Stream<ChartEvent> get onMouseOut;

  /// Stream of events that notify when mouse is moved on [ChartArea].
  Stream<ChartEvent> get onMouseMove;

  /// A pane that is rendered below all the chart elements - for use with
  /// behaviors that add elements to chart.
  Selection get lowerBehaviorPane;

  /// A pane that is rendered above all the chart elements - for use with
  /// behaviors that add elements to chart.
  Selection get upperBehaviorPane;

  /// Add a behavior to the chart.
  void addChartBehavior(ChartBehavior behavior);

  /// Remove a behavior from the chart.
  void removeChartBehavior(ChartBehavior behavior);
}

///
/// Class representing an event emitted by ChartEventSource
///
abstract class ChartEvent {
  /// DOM source event that caused this event
  Event get source;

  /// ChartSeries if any on which this event occurred
  ChartSeries get series;

  /// Column in ChartData on which this event occurred
  int get column;

  /// Row in ChartData on which this event occurred
  int get row;

  /// Value from ChartData on which the event occurred
  num get value;

  /// X position relative to the rendered chart
  num get chartX;

  /// Y position relative to the rendered chart
  num get chartY;

  factory ChartEvent(Event source, ChartArea area,
      [ChartSeries series,
      int row,
      int column,
      num value]) = DefaultChartEventImpl;
}

/// Interface implemented by chart behaviors.
/// During initialization, the behaviors subscribe to any necessary events and
/// handle them appropriately.
abstract class ChartBehavior {
  /// Called while ChartArea is being initialized.
  ///  - [area] is the ChartArea on which this behavior is installed
  ///  - [upperRenderPane] is the Selection that is rendered on top of the
  ///    chart.  Behaviors can use it to draw any visualization in response
  ///    to user actions.
  ///  - [lowerRenderPane] is the Selection that is rendered below the chart.
  void init(
      ChartArea area, Selection upperRenderPane, Selection lowerRenderPane);

  /// Clears all DOM created by this behavior, unsubscribes to event listeners
  /// and clears any state.
  void dispose();
}
