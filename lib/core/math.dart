/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

const double PI = math.PI;
const double HALF_PI = PI / 2.0;
const double TAU = PI * 2.0;
const double EPSILON = 1e-6;
const double EPSILON_SQUARE = EPSILON * EPSILON;

// Maximum (and minimum) value that would fit in Dart SMI
const int SMALL_INT_MAX = (1 << 30) - 1;
const int SMALL_INT_MIN = -1 * (1 << 30);

num cosh(num x) => ((x = math.exp(x)) + 1 / x) / 2;
num sinh(num x) => ((x = math.exp(x)) - 1 / x) / 2;
num tanh(num x) => ((x = math.exp(2 * x)) - 1) / (x + 1);
num toRadians(num degrees) => degrees * math.PI / 180.0;
num toDegrees(num radians) => radians * 180.0 / math.PI;
