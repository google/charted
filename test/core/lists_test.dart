/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.core;

testLists() {
  group('sum()', () {
    test('adds all elements in a list', () {
      expect(sum([10, 20, 30, -10]), equals(50));
    });

    test('returns 0 when the list is null or empty', () {
      expect(sum([]), equals(0));
      expect(sum(null), equals(0));
    });
  });

  group('isNullOrEmpty()', () {
    test('returns true when the iterable is null or empty', () {
      expect(isNullOrEmpty(null), isTrue);
      expect(isNullOrEmpty([]), isTrue);
    });
    test('returns false when the iterable is not null or empty', () {
      expect(isNullOrEmpty([3]), isFalse);
    });
  });
}
