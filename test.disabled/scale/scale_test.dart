/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.scale;

import 'package:charted/core/utils.dart';
import 'package:charted/interpolators/interpolators.dart';
import 'package:charted/locale/locale.dart';
import 'package:charted/scale/scale.dart';
import 'package:unittest/unittest.dart';

part 'linear_scale_test.dart';
part 'log_scale_test.dart';
part 'ordinal_scale_test.dart';
part 'scale_util_test.dart';
part 'time_scale_test.dart';

scaleTests() {
  testScaleUtil();
  testLinearScale();
  testLogScale();
  testOrdinalScale();
  testTimeScale();
}
