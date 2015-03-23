/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.format;

import 'package:charted/core/utils.dart';
import 'package:charted/locale/format.dart';
import 'package:unittest/unittest.dart';

formatTests() {
  List mockValues = [
    [0.0000000000000000000001,          'y', 100],
    [0.000000000000000000231,           'z', 231],
    [0.00000000000000004231,            'a', 42.31],
    [0.0000000000000031,                'f', 3.1],
    [0.0000000000675,                   'p', 67.5],
    [0.00000045,                        'n', 450],
    [0.0007532,                         'µ', 753.2],
    [0.2234,                            'm', 223.4],
    [167.5,                             '',  167.5],
    [334167.5,                          'k', 334.1675],
    [234555167.5,                       'M', 234.5551675],
    [565677879167.5,                    'G', 565.6778791675],
    [234324365676167.5,                 'T', 234.3243656761675],
    [6566786767957617.5,                'P', 6.566786767957618],
    [234324235364564576575,             'E', 234.32423536456457],
    [3454675678587685754647.5,          'Z', 3.4546756785876855],
    [3453543264567867855446543545167.5, 'Y', 3453543.264567868],
  ];

  test('FormatPrefix computes right SI format prefix for a given value', () {
    mockValues.forEach((d) {
      FormatPrefix prefix = new FormatPrefix(d[0]);
      expect(prefix.symbol, equals(d[1]));
      expect(prefix.scale(d[0]), closeTo(d[2], EPSILON));
    });
    mockValues.forEach((d) {
      FormatPrefix prefix = new FormatPrefix(d[0], 2);
      expect(prefix.symbol, equals(d[1]));
      expect(prefix.scale(-d[0]), closeTo(-d[2], EPSILON));
    });
  });

}
