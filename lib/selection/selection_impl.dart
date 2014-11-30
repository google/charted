/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.selection;

/**
 * Implementation of [Selection].
 * Selections cannot be created directly - they are only created using
 * the select or selectAll methods on [SelectionScope] and [Selection].
 */
class _SelectionImpl implements Selection {

  Iterable<SelectionGroup> groups;
  SelectionScope scope;

  Transition _transition;

  /**
   * Creates a new selection.
   *
   * When [source] is not specified, the new selection would have exactly
   * one group with [SelectionScope.root] as it's parent.  Otherwise, one group
   * per for each non-null element is created with element as it's parent.
   *
   * When [selector] is specified, each group contains all elements matching
   * [selector] and under the group's parent element.  Otherwise, [fn] is
   * called once per group with parent element's "data", "index" and the
   * "element" itself passed as parameters.  [fn] must return an iterable of
   * elements to be used in each group.
   */
  _SelectionImpl.all({String selector, SelectionCallback<Iterable<Element>> fn,
      SelectionScope this.scope, Selection source}) {
    assert(selector != null || fn != null);
    assert(source != null || scope != null);

    if (selector != null) {
      fn = (d, i, c) => c == null ?
          scope.root.querySelectorAll(selector) :
          c.querySelectorAll(selector);
    }

    var tmpGroups = new List(),
        index = 0;
    if (source != null) {
      scope = source.scope;
      source.groups.forEach((g) {
        g.elements.forEach((e) {
          if (e != null) {
            tmpGroups.add(
              new _SelectionGroupImpl(
                  fn(scope.datum(e), index, e), parent: e));
          }
          index++;
        });
      });
    } else {
      tmpGroups.add(
          new _SelectionGroupImpl(fn(null, 0, null), parent: scope.root));
    }
    groups = tmpGroups;
  }

  /**
   * Same as [all] but only uses the first element matching [selector] when
   * [selector] is speficied.  Otherwise, call [fn] which must return the
   * element to be selected.
   */
  _SelectionImpl.single({String selector, SelectionCallback<Element> fn,
      SelectionScope this.scope, Selection source}) {
    assert(selector != null || fn != null);
    assert(source != null || scope != null);

    if (selector != null) {
      fn = (d, i, c) => c == null ?
          scope.root.querySelector(selector) :
          c.querySelector(selector);
    }

    if (source != null) {
      scope = source.scope;
      groups = new List.generate(source.groups.length, (gi) {
        SelectionGroup g = source.groups.elementAt(gi);
        return new _SelectionGroupImpl(
            new List.generate(g.elements.length, (ei) {
          var e = g.elements.elementAt(ei);
          if (e != null) {
            var datum = scope.datum(e);
            var enterElement = fn(datum, ei, e);
            if (datum != null) {
              scope.associate(enterElement, datum);
            }
            return enterElement;
          } else {
            return null;
          }
        }), parent: g.parent);
      });
    } else {
      groups = new List.generate(1,
          (_) => new _SelectionGroupImpl(new List.generate(1,
              (_) => fn(null, 0, null), growable: false)), growable: false);
    }
  }

  /** Creates a selection using the pre-computed list of [SelectionGroup] */
  _SelectionImpl.selectionGroups(
      Iterable<SelectionGroup> this.groups, SelectionScope this.scope);

  /**
   * Creates a selection using the list of elements. All elements will
   * be part of the same group, with [SelectionScope.root] as the group's parent
   */
  _SelectionImpl.elements(Iterable elements, SelectionScope this.scope) {
    groups = new List()..add(new _SelectionGroupImpl(elements));
  }

  /**
   * Utility to evaluate value of parameters (uses value when given
   * or invokes a callback to get the value) and calls [action] for
   * each non-null element in this selection
   */
  void _do(SelectionCallback f, Function action) {
    each((d, i, e) => action(e, f == null ? null : f(scope.datum(e), i, e)));
  }

  /** Calls a function on each non-null element in the selection */
  void each(SelectionCallback fn) {
    if (fn == null) return;
    groups.forEach((SelectionGroup g) {
      var index = 0;
      g.elements.forEach((Element e) {
        if (e != null) fn(scope.datum(e), index, e);
        index++;
      });
    });
  }

  void on(String type, [SelectionCallback listener, bool capture]) {
    Function getEventHandler(d, i, e) => (Event event) {
      var old = scope.event;
      scope.event = event;
      try {
        Function.apply(listener, [d, i, e]);
      } finally {
        scope.event = old;
      }
    };

    if (!type.startsWith('.')) {
      if (listener != null) {
        // Add a listener to each element.
        each((d, i, Element e){
          var handlers = scope._listeners[e];
          if (handlers == null) scope._listeners[e] = handlers = {};
          handlers[type] = new Pair(getEventHandler(d, i, e), capture);
          e.addEventListener(type, handlers[type].first, capture);
        });
      } else {
        // Remove the listener from each element.
        each((d, i, Element e) {
          var handlers = scope._listeners[e];
          if (handlers != null && handlers[type] != null) {
            e.removeEventListener(
                type, handlers[type].first, handlers[type].last);
          }
        });
      }
    } else {
      // Remove all listeners on the event type (ignoring the namespace)
      each((d, i, Element e) {
        var handlers = scope._listeners[e],
            keys = handlers.keys,
            t = type.substring(1);
        keys.forEach((String s) {
          if (s.split('.')[0] == t) {
            e.removeEventListener(s, handlers[s].first, handlers[s].last);
          }
        });
      });
    }
  }

  int get length {
    int retval = 0;
    each((d, i, e) => retval++);
    return retval;
  }

  bool get isEmpty => length == 0;

  /** First non-null element in this selection */
  Element get first {
    for (int gi = 0; gi < groups.length; gi++) {
      SelectionGroup g = groups.elementAt(gi);
      for (int ei = 0; ei < g.elements.length; ei++) {
        if (g.elements.elementAt(ei) != null) {
          return g.elements.elementAt(ei);
        }
      }
    }
    return null;
  }

  void attr(String name, val) {
    assert(name != null && name.isNotEmpty);
    attrWithCallback(name, toCallback(val));
  }

  void attrWithCallback(String name, SelectionCallback fn) {
    assert(fn != null);
    _do(fn, (e, v) => v == null ?
        e.attributes.remove(name) : e.attributes[name] = "$v");
  }

  void classed(String name, [bool val = true]) {
    assert(name != null && name.isNotEmpty);
    classedWithCallback(name, toCallback(val));
  }

  void classedWithCallback(String name, SelectionCallback<bool> fn) {
    assert(fn != null);
    _do(fn, (e, v) =>
        v == false ? e.classes.remove(name) : e.classes.add(name));
  }

  void style(String property, String val, {String priority}) {
    assert(property != null && property.isNotEmpty);
    styleWithCallback(property,
        toCallback(val), priority: priority);
  }

  void styleWithCallback(String property,
      SelectionCallback<String> fn, {String priority}) {
    assert(fn != null);
    _do(fn, (Element e, String v) =>
        v == null || v.isEmpty ?
            e.style.removeProperty(property) :
            e.style.setProperty(property, v, priority));
  }

  void text(String val) => textWithCallback(toCallback(val));

  void textWithCallback(SelectionCallback<String> fn) {
    assert(fn != null);
    _do(fn, (e, v) => e.text = v == null ? '' : v);
  }

  void html(String val) => htmlWithCallback(toCallback(val));

  void htmlWithCallback(SelectionCallback<String> fn) {
    assert(fn != null);
    _do(fn, (e, v) => e.innerHtml = v == null ? '' : v);
  }

  void remove() => _do(null, (e, _) => e.remove());

  Selection select(String selector) {
    assert(selector != null && selector.isNotEmpty);
    return new _SelectionImpl.single(selector: selector, source: this);
  }

  Selection selectWithCallback(SelectionCallback<Element> fn) {
    assert(fn != null);
    return new _SelectionImpl.single(fn: fn, source:this);
  }

  Selection append(String tag) {
    assert(tag != null && tag.isNotEmpty);
    return appendWithCallback(
        (d, ei, e) => Namespace.createChildElement(tag, e));
  }

  Selection appendWithCallback(SelectionCallback<Element> fn) {
    assert(fn != null);
    return new _SelectionImpl.single(fn: (datum, ei, e) {
          Element child = fn(datum, ei, e);
          return child == null ? null : e.append(child);
        }, source: this);
  }

  Selection insert(String tag,
      {String before, SelectionCallback<Element> beforeFn}) {
    assert(tag != null && tag.isNotEmpty);
    return insertWithCallback(
        (d, ei, e) => Namespace.createChildElement(tag, e),
        before: before, beforeFn: beforeFn);
  }

  Selection insertWithCallback(SelectionCallback<Element> fn,
      {String before, SelectionCallback<Element> beforeFn}) {
    assert(fn != null);
    beforeFn =
        before == null ? beforeFn : (d, ei, e) => e.querySelector(before);
    return new _SelectionImpl.single(
        fn: (datum, ei, e) {
          Element child = fn(datum, ei, e);
          Element before = beforeFn(datum, ei, e);
          return child == null ? null : e.insertBefore(child, before);
        },
        source: this);
  }

  Selection selectAll(String selector) {
    assert(selector != null && selector.isNotEmpty);
    return new _SelectionImpl.all(selector: selector, source: this);
  }

  Selection selectAllWithCallback(SelectionCallback<Iterable<Element>> fn) {
    assert(fn != null);
    return new _SelectionImpl.all(fn: fn, source:this);
  }

  DataSelection data(Iterable vals, [SelectionKeyFunction keyFn]) {
    assert(vals != null);
    return dataWithCallback(toCallback(vals), keyFn);
  }

  DataSelection dataWithCallback(
      SelectionCallback<Iterable> fn, [SelectionKeyFunction keyFn]) {
    assert(fn != null);

    var enterGroups = [],
        updateGroups = [],
        exitGroups = [];

    // Create a dummy node to be used with enter() selection.
    Element dummy(val) {
      var element = new Element.tag('charted-dummy');
      scope.associate(element, val);
      return element;
    };

    // Joins data to all elements in the group.
    void join(SelectionGroup g, Iterable vals) {
      // Nodes exiting, entering and updating in this group.
      // We maintain the nodes at the same index as they currently
      // are (for exiting) or where they should be (for entering and updating)
      var update = new List(vals.length),
          enter = new List(vals.length),
          exit = new List(g.elements.length);

      // Use the key function to determine the DOM element to data
      // associations.
      if (keyFn != null) {
        var keysOnDOM = [],
            elementsByKey = {},
            valuesByKey = {},
            ei = 0,
            vi = 0;

        // Create a key to DOM element map.
        // Used later to see if an element already exists for a key.
        g.elements.forEach((e) {
          var keyValue = keyFn(scope.datum(e));
          if (elementsByKey.containsKey(keyValue)) {
            exit[ei] = e;
          } else {
            elementsByKey[keyValue] = e;
          }
          keysOnDOM.add(keyValue);
          ei++;
        });

        // Iterate through the values and find values that don't have
        // corresponding elements in the DOM, collect the entering elements.
        vals.forEach((v) {
          var keyValue = keyFn(v);
          Element e = elementsByKey[keyValue];
          if (e != null) {
            update[vi] = e;
            scope.associate(e, v);
          } else if (!valuesByKey.containsKey(keyValue)) {
            enter[vi] = dummy(v);
          }
          valuesByKey[keyValue] = v;
          elementsByKey.remove(keyValue);
          vi++;
        });

        // Iterate through the previously saved keys to
        // find a list of elements that don't have data anymore.
        // We don't use elementsByKey.keys() becuase that does not
        // guarantee the order of returned keys.
        for (int i = 0; i < g.elements.length; i++) {
          if (elementsByKey.containsKey(keysOnDOM[i])) {
            exit[i] = g.elements.elementAt(i);
          }
        }
      } else {
        // When we don't have the key function, just use list index as the key
        int updateElementsCount = math.min(g.elements.length, vals.length);
        int i = 0;

        // Collect a list of elements getting updated in this group
        for (; i < updateElementsCount; i++) {
          var e = g.elements.elementAt(i);
          if (e != null) {
            scope.associate(e, vals.elementAt(i));
            update[i] = e;
          } else {
            enter[i] = dummy(vals.elementAt(i));
          }
        }

        // List of elements newly getting added
        for (; i < vals.length; i++) {
          enter[i] = dummy(vals.elementAt(i));
        }

        // List of elements exiting this group
        for (; i < g.elements.length; i++) {
          exit[i] = g.elements.elementAt(i);
        }
      }

      // Create the element groups and set parents from the current group.
      enterGroups.add(new _SelectionGroupImpl(enter, parent: g.parent));
      updateGroups.add(new _SelectionGroupImpl(update, parent: g.parent));
      exitGroups.add(new _SelectionGroupImpl(exit, parent: g.parent));
    };

    var index = 0;
    groups.forEach((SelectionGroup g) {
      join(g, fn(scope.datum(g.parent), index++, g.parent));
    });

    return new _DataSelectionImpl(
        updateGroups, enterGroups, exitGroups, scope);
  }

  void datum(Iterable vals) {
    throw new UnimplementedError();
  }

  void datumWithCallback(SelectionCallback<Iterable> fn) {
    throw new UnimplementedError();
  }

  Transition transition() {
    return _transition = new Transition(this);
  }
}

/* Implementation of [DataSelection] */
class _DataSelectionImpl extends _SelectionImpl implements DataSelection {
  EnterSelection enter;
  ExitSelection exit;

  _DataSelectionImpl(Iterable updated, Iterable entering, Iterable exiting,
      SelectionScope scope) : super.selectionGroups(updated, scope) {
    enter = new _EnterSelectionImpl(entering, this);
    exit = new _ExitSelectionImpl(exiting, this);
  }
}

/* Implementation of [EnterSelection] */
class _EnterSelectionImpl implements EnterSelection {
  final DataSelection update;

  SelectionScope scope;
  Iterable<SelectionGroup> groups;

  _EnterSelectionImpl(Iterable this.groups, DataSelection this.update) {
    scope = update.scope;
  }

  bool get isEmpty => false;

  Selection insert(String tag,
      {String before, SelectionCallback<Element> beforeFn}) {
    assert(tag != null && tag.isNotEmpty);
    return insertWithCallback(
        (d, ei, e) => Namespace.createChildElement(tag, e),
        before: before, beforeFn: beforeFn);
  }

  Selection insertWithCallback(SelectionCallback<Element> fn,
      {String before, SelectionCallback<Element> beforeFn}) {
    assert(fn != null);
    return selectWithCallback((d, ei, e) {
      Element child = fn(d, ei, e);
      e.insertBefore(child, e.querySelector(before));
      return child;
    });
  }

  Selection append(String tag) {
    assert(tag != null && tag.isNotEmpty);
    return appendWithCallback(
        (d, ei, e) => Namespace.createChildElement(tag, e));
  }

  Selection appendWithCallback(SelectionCallback<Element> fn) {
    assert(fn != null);
    return selectWithCallback((datum, ei, e) {
          Element child = fn(datum, ei, e);
          e.children.add(child);
          return child;
        });
  }

  Selection select(String selector) {
    assert(selector == null && selector.isNotEmpty);
    return selectWithCallback((d, ei, e) => e.querySelector(selector));
  }

  Selection selectWithCallback(SelectionCallback<Element> fn) {
    var subgroups = [],
        gi = 0;
    groups.forEach((SelectionGroup g) {
      var u = update.groups.elementAt(gi),
          subgroup = [],
          ei = 0;
      g.elements.forEach((Element e) {
        if (e != null) {
          var datum = scope.datum(e),
              selected = fn(datum, ei, g.parent);
          scope.associate(selected, datum);
          u.elements[ei] = selected;
          subgroup.add(selected);
        } else {
          subgroup.add(null);
        }
        ei++;
      });
      subgroups.add(new _SelectionGroupImpl(subgroup, parent: g.parent));
      gi++;
    });
    return new _SelectionImpl.selectionGroups(subgroups, scope);
  }
}

/* Implementation of [ExitSelection] */
class _ExitSelectionImpl extends _SelectionImpl implements ExitSelection {
  final DataSelection update;
  _ExitSelectionImpl(Iterable groups, DataSelection update)
      :super.selectionGroups(groups, update.scope), update = update;
}

class _SelectionGroupImpl implements SelectionGroup {
  Iterable<Element> elements;
  Element parent;
  _SelectionGroupImpl(this.elements, {this.parent});
}
