/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.selection;

/** SelectionScope represents a scope for all the data and DOM operations. */
class SelectionScope {
  Expando _associations = new Expando();
  Expando<Map<String, Pair<Function, bool>>> _listeners = new Expando();
  Element _root;

  /** Creates a new selection scope with document as the root. */
  SelectionScope() {
    _root = document.documentElement;
  }

  /**
   * Creates a new selection scope with the first element matching
   * [selector] as the root.
   */
  SelectionScope.selector(String selector) {
    if (selector == null || selector.isEmpty ){
      throw new ArgumentError('Selector cannot be empty');
    }
    _root = document.querySelector(selector);
  }

  /**
   * Creates a new selection scope with the passed [element] as [root].
   * Charted assumes that the element is already part of the DOM.
   */
  SelectionScope.element(Element element) {
    if (element == null) {
      throw new ArgumentError('Root element for SelectionScope cannot be null');
    }
    _root = element;
  }

  /**
   * Returns the [root] element for this scope.
   * All [Selection]s and elements created using the Charted API,
   * are created as decendants of root.
   */
  Element get root => _root;

  /*
   * Current event for which a callback is being called.
   */
  Event event;

  /** Returns the stored for the given [element]. */
  datum(Element element) => element == null ? null : _associations[element];

  /** Associates data to the given [element]. */
  associate(Element element, datum) =>
      datum != null ? _associations[element] = datum : null;

  /**
   * Creates a new [Selection] containing the first element matching
   * [selector].  If no element matches, the resulting selection will
   * have a null element.
   */
  Selection select(String selector) =>
      new _SelectionImpl.single(selector: selector, scope: this);

  /**
   * Creates a new [Selection] containing all elements matching [selector].
   * If no element matches, the resulting selection will not have any
   * elements in it.
   */
  Selection selectAll(String selector) =>
      new _SelectionImpl.all(selector:selector, scope:this);

  /**
   * Creates a new [Selection] containing [elements].  Assumes that
   * all the given elements are decendants of [root] in DOM.
   */
  Selection selectElements(List<Element> elements) =>
      new _SelectionImpl.elements(elements, this);

  /**
   * Appends a new element to [root] and creates a selection containing
   * the newly added element.
   */
  Selection append(String tag) {
    var element = Namespace.createChildElement(tag, _root);
    root.children.add(element);

    return selectElements([element]);
  }
}
