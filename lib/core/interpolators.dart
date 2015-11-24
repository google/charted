//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// A collection of interpolator generators and easing functions.
///
/// Interpolators provide intermediate state when transitioning from one
/// frame to another in an animation.
///
/// Easing functions indicate progress of an animation to interpolators.
///
/// Currently provides interpolator for various types, including basic types
/// like numbers, colors, strings, transforms and for iterables.
library charted.core.interpolators;

import 'dart:math' as math;
import 'package:charted/core/utils.dart';

part 'interpolators/interpolators.dart';
part 'interpolators/easing.dart';
