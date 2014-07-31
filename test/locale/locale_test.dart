/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.locale;

import 'package:unittest/unittest.dart';
import 'package:charted/locale/locale.dart';

part 'number_format_test.dart';
part 'time_format_test.dart';

localeTests() {
  testNumberFormat();
  testTimeFormat();
}
