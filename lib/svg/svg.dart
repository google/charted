/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
/*
 * TODO(prsd): Document library
 */
library charted.svg;

import "dart:math" as math;
import "dart:html" show Element;
import "package:charted/core/core.dart";
import 'package:charted/interpolators/interpolators.dart';
import "package:charted/scale/scale.dart";
import "package:charted/selection/selection.dart";

part 'svg_arc.dart';
part 'svg_axis.dart';
part 'svg_line.dart';

/**
 * Common interface supported by all path generators.
 */
abstract class SvgPathGenerator {
  /**
   * Generate the path based on the passed data [d], element index [i]
   * and the element [e].  This method follows the same signature as the
   * other callbacks used by selection API - [ChartedCallback<String>]
   */
  String path(d, int i, Element e);
}
