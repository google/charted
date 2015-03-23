/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.scale;

testOrdinalScale() {
  test('OrdinalScale.apply returns range value of given value in domain', () {
    // Domain and range have same length.
    OrdinalScale ordinal = new OrdinalScale();
    ordinal.domain = ['Jan', 'Feb', 'Mar', 'Apr'];
    ordinal.range = [1, 3, 5, 7];
    for (var i = 0; i < ordinal.domain.length; i++){
      expect(ordinal.apply(ordinal.domain[i]), equals(ordinal.range[i]));
    }
    // Domain has more elements than range.
    ordinal.range = [1, 3, 5];
    for (var i = 0; i < ordinal.domain.length; i++){
      expect(ordinal.apply(ordinal.domain[i]),
          equals(ordinal.range[i % ordinal.range.length]));
    }
  });

  test('OrdinalScale.rangePoints sets the output range from the specified '
       'continuous interval', () {
    OrdinalScale ordinal = new OrdinalScale();
    ordinal.domain = ['Jan', 'Feb', 'Mar', 'Apr'];
    ordinal.rangePoints([0, 90]);
    expect(ordinal.range, orderedEquals([0, 30, 60, 90]));
    ordinal.rangePoints([0, 100], 1 / 3);
    expect(ordinal.range, orderedEquals([5, 35, 65, 95]));
  });

  test('OrdinalScale.rangeBands sets the output range from the specified '
       'continuous interval', () {
    OrdinalScale ordinal = new OrdinalScale();
    ordinal.domain = ['Jan', 'Feb', 'Mar'];
    ordinal.rangeBands([0, 90]);
    expect(ordinal.range, orderedEquals([0, 30, 60]));
    ordinal.rangeBands([0, 100], 1 / 3);
    expect(ordinal.range, orderedEquals([10.0, 40.0, 70.0]));
    ordinal.rangeBands([0, 90], 2 / 5, 1 / 5);
    expect(ordinal.range, orderedEquals([6.0, 36.0, 66.0]));
    ordinal.rangeBands([90, 0], 2 / 5, 1 / 5);
    expect(ordinal.range, orderedEquals([66.0, 36.0, 6.0]));
  });

  test('OrdinalScale.rangeBands sets the output range from the specified '
       'continuous interval and rounds them to integers', () {
    OrdinalScale ordinal = new OrdinalScale();
    ordinal.domain = ['Jan', 'Feb', 'Mar'];
    ordinal.rangeRoundBands([0, 100]);
    expect(ordinal.range, orderedEquals([1.0, 34.0, 67.0]));
    ordinal.rangeRoundBands([0, 110], 1 / 3);
    expect(ordinal.range, orderedEquals([11.0, 44.0, 77.0]));
    ordinal.rangeRoundBands([0, 100], 2 / 5, 1 / 5);
    expect(ordinal.range, orderedEquals([7.0, 40.0, 73.0]));
    ordinal.rangeRoundBands([100, 0], 2 / 5, 1 / 5);
    expect(ordinal.range, orderedEquals([73.0, 40.0, 7.0]));
  });

  test('OrdinalScale.rangeExtent gets [smallest, largest] range values', () {
    OrdinalScale ordinal = new OrdinalScale();
    ordinal.domain = ['Jan', 'Feb', 'Mar'];
    ordinal.range = [10, 30, 100];
    expect(ordinal.rangeExtent(), orderedEquals([10, 100]));
    ordinal.range = [100, 20, 1];
    expect(ordinal.rangeExtent(), orderedEquals([1, 100]));
  });
}