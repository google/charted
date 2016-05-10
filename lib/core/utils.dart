//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// A collection of utilities for use by rest of the library and it's users
library charted.core.utils;

import "dart:html" show Element, NodeTreeSanitizer;
import "dart:math" as math;
import "dart:async";

import "package:intl/intl.dart" show BidiFormatter, Bidi, TextDirection;
import "package:collection/collection.dart";
import "package:quiver/core.dart";

part 'utils/color.dart';
part 'utils/disposer.dart';
part 'utils/lists.dart';
part 'utils/math.dart';
part 'utils/namespace.dart';
part 'utils/object_factory.dart';
part 'utils/rect.dart';
part 'utils/bidi_formatter.dart';

const String ORIENTATION_LEFT = 'left';
const String ORIENTATION_RIGHT = 'right';
const String ORIENTATION_TOP = 'top';
const String ORIENTATION_BOTTOM = 'bottom';

/// Identity function that returns the value passed as it's parameter.
/*=T*/ identityFunction/*<T>*/(/*=T*/x) => x;

/// Function that formats a value to String.
typedef String FormatFunction(value);

/// Test if the given String or Iterable, [val] is null or empty
bool isNullOrEmpty(val) {
  assert(val == null || val is String || val is Iterable);
  return val == null || val.isEmpty;
}

/// An empty tree sanitizer for use with Element.html
/// This sanitizer must not be used when attaching user input to the DOM.
class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(_) {}
}
