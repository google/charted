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
  group('isNullOrEmpty()', () {
    test('returns true when the object is null or empty', () {
      expect(isNullOrEmpty(null), isTrue);
      expect(isNullOrEmpty(''), isTrue);
      expect(isNullOrEmpty({}), isTrue);
      expect(isNullOrEmpty([]), isTrue);
    });
    test('returns false when the object is not null or empty', () {
      expect(isNullOrEmpty([3]), isFalse);
    });
  });

  testLists();
  testNamespace();
  testColor();
  testMath();
  testObjectFactory();
}
