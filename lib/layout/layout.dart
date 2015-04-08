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
library charted.layout;

import 'dart:html' show Element;
import 'package:charted/core/utils.dart';
import 'package:charted/selection/selection.dart';
import 'package:charted/svg/shapes.dart' show SvgArcData;
import 'dart:math' as math;

part 'src/pie_layout.dart';
part 'src/hierarchy_layout.dart';
part 'src/treemap_layout.dart';
