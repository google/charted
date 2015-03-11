/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core.interpolators;

EasingFn clampEasingFn(EasingFn f) =>
    (t) => t <= 0 ? 0 : t >= 1 ? 1 : f(t);

// Ease-in is defined is the identifyFunction.
/** Ease-out */
EasingFn reverseEasingFn(EasingFn f) =>
    (t) => 1 - f(1 - t);

/** Ease-in-out */
EasingFn reflectEasingFn(EasingFn f) =>
    (t) => .5 * (t < .5 ? f(2 * t) : (2 - f(2 - 2 * t)));

/** Ease-out-in */
EasingFn reflectReverseEasingFn(EasingFn f) =>
    reflectEasingFn(reverseEasingFn(f));

EasingFn easePoly([e = 1]) => (t) => math.pow(t, e);

EasingFn easeElastic([a = 1, p = 0.45]) {
  var s = p / 2 * math.PI * math.asin(1 / a);
  return (t) => 1 + a * math.pow(2, -10 * t) *
      math.sin((t - s) * 2 * math.PI / p);
}

EasingFn easeBack([s = 1.70158]) =>
    (num t) => t * t * ((s + 1) * t - s);

EasingFn easeQuad() => (num t) => t * t;

EasingFn easeCubic() => (num t) => t * t * t;

EasingFn easeCubicInOut() =>
    (num t) {
      if (t <= 0) return 0;
      if (t >= 1) return 1;
      var t2 = t * t,
          t3 = t2 * t;
      return 4 * (t < .5 ? t3 : 3 * (t - t2) + t3 - .75);
    };

EasingFn easeSin() =>
    (num t) => 1 - math.cos(t * math.PI / 2);

EasingFn easeExp() =>
    (num t) => math.pow(2, 10 * (t - 1));

EasingFn easeCircle() =>
    (num t) => 1 - math.sqrt(1 - t * t);

EasingFn easeBounce() =>
    (num t) =>  t < 1 / 2.75 ?
        7.5625 * t * t : t < 2 / 2.75 ?
            7.5625 * (t -= 1.5 / 2.75) * t + .75 : t < 2.5 / 2.75 ?
                7.5625 * (t -= 2.25 / 2.75) * t + .9375
                    : 7.5625 * (t -= 2.625 / 2.75) * t + .984375;
