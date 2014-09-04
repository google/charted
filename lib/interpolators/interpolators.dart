/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.interpolators;

import 'dart:math' as math;
import 'package:charted/core/core.dart';
import 'package:csslib/parser.dart' as cssParser;

part 'interpolators_impl.dart';
part 'easing_impl.dart';

/**
 * [InterpolateFn] accepts [t], such that 0.0 < t < 1.0 and returns
 * a value in a pre-defined range.
 */
typedef InterpolateFn(num t);

/**
 * [Interpolator] accepts two parameters [a], [b] and returns a function
 * that takes a number t, such that 0.0 <= t <= 1.0 and interpolates it
 * to a value between [a] and [b]
 */
typedef InterpolateFn Interpolator(a, b);

/** [EasingFn] is same as [InterpolateFn] but is for computing easing */
typedef EasingFn(num t);

/*
 * Creates an easing function based on type and mode.
 * Assumes that all easing function generators support calling
 * without any parameters.
 */
EasingFn easeFunctionByName(String type, [String mode = 'in', List params]) {
  const Map _easeType = const {
    'linear': identityFunction,
    'poly': easePoly,
    'quad': easeQuad,
    'cubic': easeCubic,
    'sin': easeSin,
    'exp': easeExp,
    'circle': easeCircle,
    'elastic': easeElastic,
    'back': easeBack,
    'bounce': easeBounce
  };

  const Map _easeMode = const {
    'in': identityFunction,
    'out': reverseEasingFn,
    'in-out': reflectEasingFn,
    'out-in': reflectReverseEasingFn
  };

  assert(_easeType.containsKey(type));
  assert(_easeMode.containsKey(mode));

  var fn = Function.apply(_easeType[type], params);
  return clampEasingFn(_easeMode[mode](fn));
}
