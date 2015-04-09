/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.event;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:charted/event/event.dart';


part 'timer_test.dart';

eventTests() {
  testTimer();
}
