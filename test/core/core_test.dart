/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.core;

import 'dart:html' show document, Element;
import 'package:unittest/unittest.dart';
import 'package:charted/core/core.dart';

import 'dart:math' as math;

part 'lists_test.dart';
part 'namespace_test.dart';
part 'color_test.dart';
part 'math_test.dart';
part 'object_factory_test.dart';

coreTests() {
  test('toCallback() creates a callback to return the given value', () {
    num value = 100;
    ChartedCallback<num> cb = toCallback(value);
    expect(cb(null, null, null), equals(value));
  });

  test('toValueAccessor() creates an accessor to return the given value', () {
    num value = 100;
    ChartedValueAccessor<num> cb = toValueAccessor(value);
    expect(cb(null, null), equals(value));
  });


  testLists();
  testNamespace();
  testColor();
  testMath();
  testObjectFactory();
}
