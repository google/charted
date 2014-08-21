/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
import 'package:unittest/html_config.dart';
import 'transformer_test.dart' as tests;

main() {
  useHtmlConfiguration(false);
  tests.transformerTests();
}
