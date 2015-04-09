//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.utils;

/// Mathematical constant PI
const double PI = math.PI;

/// PI * 0.5
const double HALF_PI = PI / 2.0;

/// PI * 2
/// Ratio constant of a circle's circumference to radius
const double TAU = PI * 2.0;

/// An arbitrary small possible number
const double EPSILON = 1e-6;

/// EPSILON * EPSILON, where EPSILON is a arbitrarily small positive number
const double EPSILON_SQUARE = EPSILON * EPSILON;

/// Maximum value of Dart SMI.
/// On 32 bit machines, numbers above this have an additional lookup overhead.
const int SMALL_INT_MAX = (1 << 30) - 1;

/// Minimum value of Dart SMI.
/// On 32 bit machines, numbers below this have an additional lookup overhead.
const int SMALL_INT_MIN = -1 * (1 << 30);

/// Hyperbolic cosine.
num cosh(num x) => ((x = math.exp(x)) + 1 / x) / 2;

/// Hyperbolic sine.
num sinh(num x) => ((x = math.exp(x)) - 1 / x) / 2;

/// Hyperbolic tangent.
num tanh(num x) => ((x = math.exp(2 * x)) - 1) / (x + 1);

/// Converts [degrees] to radians.
num toRadians(num degrees) => degrees * math.PI / 180.0;

/// Converts [radians] to degrees.
num toDegrees(num radians) => radians * 180.0 / math.PI;
