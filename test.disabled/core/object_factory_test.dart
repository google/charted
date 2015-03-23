/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.core;

class MockObject { }
class MockCreateFailObject {
  factory MockCreateFailObject() => null;
}

testObjectFactory() {
  ObjectFactory factory = new ObjectFactory();
  factory.register("mock", () => new MockObject());
  factory.register("mockfail", () => new MockCreateFailObject());

  group('ObjectFactory.create()', () {
    test('creates an object of a registered factory', () {
      expect(factory.create("mock"), new isInstanceOf<MockObject>());
    });
    test('throwsArgumentError if a factory returns null', () {
      expect(() => factory.create("mockfail"), throwsArgumentError);
    });
    test('throwsArgumentError when a factory is not registered', () {
      expect(() => factory.create("notregistered"), throwsArgumentError);
    });
  });
}
