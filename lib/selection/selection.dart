/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
/*
 * TODO(prsd): Document library
 */
library charted.selection;

import "dart:html" show Element, Event, document;
import "dart:math" as math;
import "package:charted/core/core.dart";
import "package:charted/transition/transition.dart";

part "selection_scope.dart";
part "selection_impl.dart";

/**
 * Callback to access key value from a given data object. During the process
 * of binding data to Elements, the key values are used to match Elements
 * that have previously bound data
 */
typedef SelectionKeyFunction(datum);

/**
 * Callback for all DOM related operations - The first parameter [datum] is
 * the piece of data associated with the node, [ei] is the index of the
 * element in it's group and [c] is the context to which the data is
 * associated to.
 */
typedef E SelectionCallback<E>(datum, int index, Element element);

/** Callback used to access a value from a datum */
typedef E SelectionValueAccessor<E>(datum, int index);

/** Create a ChartedCallback that always returns [val] */
SelectionCallback toCallback(val) => (datum, index, element) => val;

/** Create a ChartedValueAccessor that always returns [val] */
SelectionValueAccessor toValueAccessor(val) => (datum, index) => val;

/**
 * [Selection] is a collection of elements - this collection defines
 * operators that can be applied on all elements of the collection.
 *
 * All operators accept parameters either as a constant value or a callback
 * function (typically using the named parameters "val" and "fn"). These
 * operators, when invoked with the callback function, the function is
 * called once per element and is passed the "data" associated, the "index"
 * and the element itself.
 */
abstract class Selection {
  /**
   * Collection of groups - A selection when created by calling [selectAll]
   * on an existing [Selection], could contain more than one group.
   */
  Iterable<SelectionGroup> groups;

  /**
   * Scope of this selection that manages the element, data associations for
   * all elements in this selection (and the sub-selections)
   */
  SelectionScope get scope;

  /** Indicates if this selection is empty */
  bool get isEmpty;

  /** Number of elements in this selection */
  int get length;

  /** First non-null element in this selection, if any. */
  Element get first;

  /**
   * Creates and returns a new [Selection] containing the first element
   * matching [selector] under each element in the current selection.
   *
   * If an element does not have a matching decendant, a placeholder is used
   * in it's position - thus being able to match the indices of elements in
   * the current and the created sub-selection.
   *
   * Any data bound to elements in this selection is inherited by the
   * selected decendants.
   */
  Selection select(String selector);

  /**
   * Same as [select], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the selected element that will
   * be selected.
   */
  Selection selectWithCallback(SelectionCallback<Element> fn);

  /**
   * Creates and returns a new [Selection] containing all elements matching
   * [selector] under each element in the current selection.
   *
   * The resulting [Selection] is nested with elements from current selection
   * as parents and the selected decendants grouped by elements in the
   * current selection.  When no decendants match the selector, the
   * collection of selected elements in a group is empty.
   *
   * Data bound to the elements is not automatically inherited by the
   * selected decendants.
   */
  Selection selectAll(String selector);

  /**
   * Same as [selectAll], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get a collection of selected
   * elements that will be part of the new selection.
   */
  Selection selectAllWithCallback(SelectionCallback<Iterable<Element>> fn);

  /**
   * Sets the attribute [name] on all elements when [val] is not null.
   * Removes the attribute when [val] is null.
   */
  void attr(String name, val);

  /**
   * Same as [attr], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the value of the attribute.
   */
  void attrWithCallback(String name, SelectionCallback fn);

  /**
   * Ensures presence of a class when [val] is true.  Ensures that the class
   * isn't present if [val] is false.
   */
  void classed(String name, [bool val = true]);

  /**
   * Same as [classed], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the boolean value that
   * indicates if the class must be added or removed.
   */
  void classedWithCallback(String name, SelectionCallback<bool> fn);

  /** Sets CSS [property] to [val] on all elements in the selection. */
  void style(String property, val, {String priority});

  /**
   * Same as [style], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the value of the property.
   */
  void styleWithCallback(String property,
      SelectionCallback<String> fn, {String priority});

  /**
   * Sets textContent of all elements in the selection to [val]. A side-effect
   * of this call is that any children of these elements will not be part of
   * the DOM anymore.
   */
  void text(String val);

  /**
   * Same as [text], but calls [fn] for each non-null element in
   * the selection (with data associated to the element, index of the
   * element in it's group and the element itself) to get the text content
   */
  void textWithCallback(SelectionCallback<String> fn);

  /**
   * Sets innerHtml of all elements in the selection to [val]. A side-effect
   * of this call is that any children of these elements will not be part of
   * the DOM anymore.
   */
  void html(String val);

  /**
   * Same as [html], but calls [fn] for each non-null element in
   * the selection (with data associated to the element, index of the
   * element in it's group and the element itself) to get the html content
   */
  void htmlWithCallback(SelectionCallback<String> fn);

  /**
   * Appends a new child element to each element in the selection.
   *
   * Returns a [Selection] containing the newly created elements. As with
   * [select], any data bound to the elements in this selection is inherited
   * by the new elements.
   */
  Selection append(String tag);

  /**
   * Same as [append], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the element to be appended.
   */
  Selection appendWithCallback(SelectionCallback<Element> fn);

  /**
   * Inserts a child node to each element in the selection before the first
   * element matching [before] or before the element returned by [beforeFn].
   *
   * Returns a [Selection] containing the newly created elements. As with
   * [select], any data bound to the elements in this selection is inherited
   * by the new elements.
   */
  Selection insert(String tag,
      {String before, SelectionCallback<Element> beforeFn});

  /**
   * Same as [insert], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the element to be inserted.
   */
  Selection insertWithCallback(SelectionCallback<Element> fn,
      {String before, SelectionCallback<Element> beforeFn});

  /** Removes all selected elements from the DOM */
  void remove();

  /** Calls [fn] on each element in this selection */
  void each(SelectionCallback fn);

  /**
   * Adds or removes an event [listener] to each element in the selection for
   * the specified [type] (Eg: "mouseclick", "mousedown")
   *
   * Any existing listener of the same type will be removed.  To register
   * multiple listener for the same event type, the [type] can be suffixed
   * with a namespace. (Eg: "mouseclick.foo", "mousedown.bar")
   *
   * When [listener] is null, any existing listener of the same type and in
   * the same namespace will be removed (Eg: Using "mouseclick.foo" as type
   * will only remove listeners for "mouseclick.foo" and not "mouseclick.bar")
   *
   * To remove listeners of an event type in all namespaces, prefix the type
   * with a "." (Eg: ".mouseclick" will remove "mouseclick.bar",
   * "mouseclick .foo" and all other mouseclick event listeners)
   *
   * To summarize, [type] can be any DOM event type optionally in the format
   * "event.namespace" where event is the DOM event type and namespace is
   * used to distinguish between added listeners.
   */
  void on(String type, [SelectionCallback listener, bool capture]);

  /**
   * Associates data with the selected elements.
   * Computes the enter, update and exit selections.
   */
  DataSelection data(Iterable vals, [SelectionKeyFunction keyFn]);

  /**
   * Same as [data], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the data to be set on the
   * current element.
   */
  DataSelection dataWithCallback(
      SelectionCallback<Iterable> fn, [SelectionKeyFunction keyFn]);

  /**
   * Associates data with all the elements - no join is performed. Unlike
   * [data], this does not compute the enter, update and exit selections.
   */
  void datum(Iterable vals);

  /**
   * Same as [datum], but calls [fn] for each non-null element in the
   * selection (with data associated to the element, index of the element in
   * it's group and the element itself) to get the data to be set on the
   * current element.
   */
  void datumWithCallback(SelectionCallback<Iterable> fn);

  /**
   * Starts a transition for the current selection. Transitions behave much
   * like selections, except operators animate smoothly over time rather than
   * applying instantaneously.
   */
  Transition transition();
}


/*
 * Group of elements in the selection.
 * Each selection may contain more than one group of elements.
 */
abstract class SelectionGroup {
  Iterable<Element> elements;
  Element parent;
}


/**
 * [EnterSelection] is a sub-selection that represents missing elements of a
 * selection - an element is considered missing when there is data and no
 * corresponding element in a selection.
 */
abstract class EnterSelection {
  /**
   * Indicate if this selection is empty
   * See [Selection.isEmpty] for more information.
   */
  bool get isEmpty;

  /** [DataSelection] that corresponds to this selection. */
  DataSelection get update;

  /**
   * Appends an element to all elements in this selection and return
   * [Selection] containing the newly added elements.
   *
   * See [Selection.append] for more information.
   * The new nodes are merged into the [DataSelection]
   */
  Selection append(String tag);

  /**
   * Same as [append] but calls [fn] to get the element to be appended.
   * See [Selection.appendWithCallback] for more information.
   */
  Selection appendWithCallback(SelectionCallback<Element> fn);

  /**
   * Insert a child node to each element in the selection and return
   * [Selection] containing the newly added elements.
   *
   * See [Selection.insert] for more information.
   * The new nodes are merged into the [UpdateSelection]
   */
  Selection insert(String tag,
      {String before, SelectionCallback<Element> beforeFn});

  /**
   * Same as [insert] but calls [fn] to get the element to be inserted.
   * See [Selection.insertWithCallback] for more information.
   */
  Selection insertWithCallback(SelectionCallback<Element> fn,
      {String before, SelectionCallback<Element> beforeFn});

  /**
   * For each element in the current selection, select exactly one
   * decendant and return [Selection] containing the selected elements.
   *
   * See [Selection.select] for more information.
   */
  Selection select(String selector);

  /**
   * Same as [select] but calls [fn] to get the element to be inserted.
   * See [Selection.selectWithCallback] for more information.
   */
  Selection selectWithCallback(SelectionCallback<Element> fn);
}

/*
 * [ExitSelection] is a sub-selection that represents elements that don't
 * have data associated to them.
 */
abstract class ExitSelection extends Selection {
  DataSelection get update;
}

/*
 * Selection that consists elements in the selection that aren't part of
 * [EnterSelection] or the [ExitSelection]
 *
 * An [UpdateSelection] is only available after data() is attached and is
 * currently exactly the same as [Selection] itself.
 */
abstract class DataSelection extends Selection {
  /**
   * A view of the current selection that contains a collection of data
   * elements which weren't associated with an element in the DOM.
   */
  EnterSelection get enter;

  /**
   * A view of the current selection containing elements that don't have data
   * associated with them.
   */
  ExitSelection get exit;
}
