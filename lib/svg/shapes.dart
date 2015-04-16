//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.svg.shapes;

import "dart:html" show Element;
import "dart:math" as math;

import "package:charted/core/utils.dart";
import "package:charted/core/interpolators.dart";
import "package:charted/selection/selection.dart";

part 'shapes/arc.dart';
part 'shapes/line.dart';
part 'shapes/area.dart';
part 'shapes/rect.dart';

/// Common interface provided by all shape implementations.
abstract class SvgShape {
  /// Generate the path based on the passed data [d], element index [i]
  /// and the element [e].  This method follows the same signature as the
  /// other callbacks used by selection API - [ChartedCallback<String>]
  String path(d, int i, Element e);
}
