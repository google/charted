/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

typedef T ObjectCreator<T>();

/**
 * Provides a registry and factory service.
 *
 * Registration:
 * ObjectFactory.register(“type”, () => { new TypeCreator(); });
 *
 * Usage:
 * instance = ObjectFactory.create('type');
 */
class ObjectFactory<T> {
  Map<String, ObjectCreator<T>> _components = {};

  /**
   * Registers a component.
   */
  void register(String name, ObjectCreator<T> creator) {
    _components[name] = creator;
  }

  /**
   * Creates an instance of the component.
   */
  T create(String name) {
    if (!_components.containsKey(name)) {
      throw new ArgumentError('Element $name not found in ComponentFactory');
    }
    var creator = _components[name],
        instance = creator();
    if (instance == null) {
      throw new ArgumentError('Component $name initialization failed.');
    }
    return instance;
  }
}
