/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.svg;

import 'dart:async';
import 'dart:html' show document, Element;
import 'package:charted/core/utils.dart';
import 'package:charted/scale/scale.dart';
import 'package:charted/selection/selection.dart';
import 'package:charted/svg/svg.dart';
import 'package:charted/interpolators/interpolators.dart';
import 'package:unittest/unittest.dart';

part 'svg_arc_test.dart';
part 'svg_axis_test.dart';
part 'svg_line_test.dart';

svgTests() {
  testSvgArc();
  testSvgAxis();
  testSvgLine();
}
