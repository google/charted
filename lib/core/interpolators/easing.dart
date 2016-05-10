//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.interpolators;

const String EASE_TYPE_LINEAR = 'linear';
const String EASE_TYPE_POLY = 'poly';
const String EASE_TYPE_QUAD = 'quad';
const String EASE_TYPE_CUBIC = 'cubic';
const String EASE_TYPE_SIN = 'sin';
const String EASE_TYPE_EXP = 'exp';
const String EASE_TYPE_CIRCLE = 'circle';
const String EASE_TYPE_ELASTIC = 'elastic';
const String EASE_TYPE_BACK = 'back';
const String EASE_TYPE_BOUNCE = 'bounce';

const String EASE_MODE_IN = 'in';
const String EASE_MODE_OUT = 'out';
const String EASE_MODE_IN_OUT = 'in-out';
const String EASE_MODE_OUT_IN = 'out-in';

/// [EasingFunction] manipulates progression of an animation.  The returned
/// value is passed to an [Interpolator] to generate intermediate state.
typedef num EasingFunction(num t);

/// Alters behavior of the [EasingFunction].  Takes [fn] and returns an
/// altered [EasingFunction].
typedef EasingFunction EasingModeFunction(EasingFunction fn);

/// Clamps transition progress to stay between 0.0 and 1.0
EasingFunction clampEasingFn(EasingFunction f) =>
    (t) => t <= 0 ? 0 : t >= 1 ? 1 : f(t);

//
// Implementation of easing modes.
//

EasingFunction reverseEasingFn(EasingFunction f) => (t) => 1 - f(1 - t);

EasingFunction reflectEasingFn(EasingFunction f) =>
    (t) => .5 * (t < .5 ? f(2 * t) : (2 - f(2 - 2 * t)));

EasingFunction reflectReverseEasingFn(EasingFunction f) =>
    reflectEasingFn(reverseEasingFn(f));

//
// Implementation of easing function generators.
//

EasingFunction easePoly([e = 1]) => (t) => math.pow(t, e);

EasingFunction easeElastic([a = 1, p = 0.45]) {
  var s = p / 2 * math.PI * math.asin(1 / a);
  return (t) =>
      1 + a * math.pow(2, -10 * t) * math.sin((t - s) * 2 * math.PI / p);
}

EasingFunction easeBack([s = 1.70158]) => (num t) => t * t * ((s + 1) * t - s);

EasingFunction easeQuad() => (num t) => t * t;

EasingFunction easeCubic() => (num t) => t * t * t;

EasingFunction easeCubicInOut() => (num t) {
      if (t <= 0) return 0;
      if (t >= 1) return 1;
      var t2 = t * t, t3 = t2 * t;
      return 4 * (t < .5 ? t3 : 3 * (t - t2) + t3 - .75);
    };

EasingFunction easeSin() => (num t) => 1 - math.cos(t * math.PI / 2);

EasingFunction easeExp() => (num t) => math.pow(2, 10 * (t - 1));

EasingFunction easeCircle() => (num t) => 1 - math.sqrt(1 - t * t);

EasingFunction easeBounce() => (num t) => t < 1 / 2.75
    ? 7.5625 * t * t
    : t < 2 / 2.75
        ? 7.5625 * (t -= 1.5 / 2.75) * t + .75
        : t < 2.5 / 2.75
            ? 7.5625 * (t -= 2.25 / 2.75) * t + .9375
            : 7.5625 * (t -= 2.625 / 2.75) * t + .984375;
