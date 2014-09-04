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
typedef num EasingFn(num t);

/**
 * [EasingMode] a mode that can be applied on a [Easingfn] and returns a new
 * EasingFn.
 */
typedef EasingFn EasingMode(EasingFn fn);

/**
 * List of registered interpolators - [interpolator] iterates through
 * this list from backwards and the first non-null interpolate function
 * is returned to the caller.
 */
List<Interpolator> interpolators = [ interpolatorByType ];

/**
 * Returns a default interpolator between values [a] and [b]. Unless
 * more interpolators are added, one of the internal implementations are
 * selected by the type of [a] and [b].
 */
InterpolateFn interpolator(a, b) {
  var fn, i = interpolators.length;
  while (--i >= 0 && fn == null) {
    fn = interpolators[i](a, b);
  }
  return fn;
}

/** Returns an interpolator based on the type of [a] and [b] */
InterpolateFn interpolatorByType(a, b) =>
    (a is List && b is List) ? interpolateList(a, b) :
    (a is Map && b is Map) ? interpolateMap(a, b) :
    (a is String && b is String) ? interpolateString(a, b) :
    (a is num && b is num) ? interpolateNumber(a, b) :
    (a is Color && b is Color) ? interpolateColor(a, b) :
    (t) => (t <= 0.5) ? a : b;

/*
 * Creates an easing function based on type and mode.
 * Assumes that all easing function generators support calling
 * without any parameters.
 */
EasingFn easeFunctionByName(String type,
    [String mode = EASE_MODE_IN, List params]) {
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
