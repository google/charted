//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.interpolators;

/// [Interpolator] accepts [t], such that 0.0 < t < 1.0 and returns
/// a value in a pre-defined range.
typedef Interpolator(num t);

/// [InterpolatorGenerator] accepts two parameters [a], [b] and returns an
/// [Interpolator] for transitioning from [a] to [b]
typedef Interpolator InterpolatorGenerator(a, b);

/// List of registered interpolators - [createInterpolatorFromRegistry]
/// iterates through this list from backwards and the first non-null
/// interpolate function is returned to the caller.
List<InterpolatorGenerator> _interpolators = [createInterpolatorByType];

/// Returns a default interpolator between values [a] and [b]. Unless
/// more interpolators are added, one of the internal implementations are
/// selected by the type of [a] and [b].
Interpolator createInterpolatorFromRegistry(a, b) {
  Interpolator fn;
  int i = _interpolators.length;
  while (--i >= 0 && fn == null) {
    fn = _interpolators[i](a, b);
  }
  return fn;
}

/// Creates an interpolator based on the type of [a] and [b].
///
/// Usage note: Use this method only when type of [a] and [b] are not known.
///     When used, this function will prevent tree shaking of all built-in
///     interpolators.
Interpolator createInterpolatorByType(a, b) {
  if (a is List && b is List) {
    return createListInterpolator(a, b);
  } else if (a is Map && b is Map) {
    return createMapInterpolator(a, b);
  } else if (a is String && b is String) {
    return createStringInterpolator(a, b);
  } else if (a is num && b is num) {
    return createNumberInterpolator(a, b);
  } else if (a is Color && b is Color) {
    return createRgbColorInterpolator(a, b);
  } else {
    return (t) => (t <= 0.5) ? a : b;
  }
}

//
// Implementations of InterpolatorGenerator
//

/// Generate a numeric interpolator between numbers [a] and [b]
Interpolator createNumberInterpolator(num a, num b) {
  b -= a;
  return (t) => a + b * t;
}

/// Generate a rounded number interpolator between numbers [a] and [b]
Interpolator createRoundedNumberInterpolator(num a, num b) {
  b -= a;
  return (t) => (a + b * t).round();
}

/// Generate an interpolator between two strings [a] and [b].
///
/// The interpolator will interpolate all the number pairs in both strings
/// that have same number of numeric parts.  The function assumes the non
/// number part of the string to be identical and would use string [b] for
/// merging the non numeric part of the strings.
///
/// Eg: Interpolate between $100.0 and $150.0
Interpolator createStringInterpolator(String a, String b) {
  if (a == null || b == null) return (t) => b;

  // See if both A and B represent colors as RGB or HEX strings.
  // If yes, use color interpolators
  if (Color.isRgbColorString(a) && Color.isRgbColorString(b)) {
    return createRgbColorInterpolator(
        new Color.fromRgbString(a), new Color.fromRgbString(b));
  }

  // See if both A and B represent colors as HSL strings.
  // If yes, use color interpolators.
  if (Color.isHslColorString(a) && Color.isHslColorString(b)) {
    return createHslColorInterpolator(
        new Color.fromHslString(a), new Color.fromHslString(b));
  }

  var numberRegEx = new RegExp(r'[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?'),
      numMatchesInA = numberRegEx.allMatches(a),
      numMatchesInB = numberRegEx.allMatches(b),
      stringParts = [],
      numberPartsInA = [],
      numberPartsInB = [],
      interpolators = [],
      s0 = 0;

  numberPartsInA.addAll(numMatchesInA.map((m) => m.group(0)));

  for (Match m in numMatchesInB) {
    stringParts.add(b.substring(s0, m.start));
    numberPartsInB.add(m.group(0));
    s0 = m.end;
  }

  if (s0 < b.length) stringParts.add(b.substring(s0));

  int numberLength = math.min(numberPartsInA.length, numberPartsInB.length);
  int maxLength = math.max(numberPartsInA.length, numberPartsInB.length);
  for (var i = 0; i < numberLength; i++) {
    interpolators.add(createNumberInterpolator(
        num.parse(numberPartsInA[i]), num.parse(numberPartsInB[i])));
  }
  if (numberPartsInA.length < numberPartsInB.length) {
    for (var i = numberLength; i < maxLength; i++) {
      interpolators.add(createNumberInterpolator(
          num.parse(numberPartsInB[i]), num.parse(numberPartsInB[i])));
    }
  }

  return (t) {
    StringBuffer sb = new StringBuffer();
    for (var i = 0; i < stringParts.length; i++) {
      sb.write(stringParts[i]);
      if (interpolators.length > i) {
        sb.write(interpolators[i](t));
      }
    }
    return sb.toString();
  };
}

/// Generate an interpolator for RGB values.
Interpolator createRgbColorInterpolator(Color a, Color b) {
  if (a == null || b == null) return (t) => b;
  var ar = a.r, ag = a.g, ab = a.b, br = b.r - ar, bg = b.g - ag, bb = b.b - ab;

  return (t) => new Color.fromRgba((ar + br * t).round(), (ag + bg * t).round(),
      (ab + bb * t).round(), 1.0).toRgbaString();
}

/// Generate an interpolator using HSL color system converted to Hex string.
Interpolator createHslColorInterpolator(Color a, Color b) {
  if (a == null || b == null) return (t) => b;
  var ah = a.h, as = a.s, al = a.l, bh = b.h - ah, bs = b.s - as, bl = b.l - al;

  return (t) => new Color.fromHsla((ah + bh * t).round(), (as + bs * t).round(),
      (al + bl * t).round(), 1.0).toHslaString();
}

/// Generates an interpolator to interpolate each element between lists
/// [a] and [b] using registered interpolators.
Interpolator createListInterpolator(List a, List b) {
  if (a == null || b == null) return (t) => b;
  var x = [],
      aLength = a.length,
      numInterpolated = b.length,
      n0 = math.min(aLength, numInterpolated),
      output = new List.filled(math.max(aLength, numInterpolated), null),
      i;

  for (i = 0; i < n0; i++) x.add(createInterpolatorFromRegistry(a[i], b[i]));
  for (; i < aLength; ++i) output[i] = a[i];
  for (; i < numInterpolated; ++i) output[i] = b[i];

  return (t) {
    for (i = 0; i < n0; ++i) output[i] = x[i](t);
    return output;
  };
}

/// Generates an interpolator to interpolate each value on [a] to [b] using
/// registered interpolators.
Interpolator createMapInterpolator(Map a, Map b) {
  if (a == null || b == null) return (t) => b;
  var interpolatorsMap = new Map(),
      output = new Map(),
      aKeys = a.keys.toList(),
      bKeys = b.keys.toList();

  aKeys.forEach((k) {
    if (b[k] != null) {
      interpolatorsMap[k] = (createInterpolatorFromRegistry(a[k], b[k]));
    } else {
      output[k] = a[k];
    }
  });

  bKeys.forEach((k) {
    if (output[k] == null) {
      output[k] = b[k];
    }
  });

  return (t) {
    interpolatorsMap.forEach((k, v) => output[k] = v(t));
    return output;
  };
}

/// Returns the interpolator that interpolators two transform strings
/// [a] and [b] by their translate, rotate, scale and skewX parts.
Interpolator createTransformInterpolator(String a, String b) {
  if (a == null || b == null) return (t) => b;
  var numRegExStr = r'[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?',
      numberRegEx = new RegExp(numRegExStr),
      translateRegEx =
      new RegExp(r'translate\(' + '$numRegExStr,$numRegExStr' + r'\)'),
      scaleRegEx =
      new RegExp(r'scale\(' + numRegExStr + r',' + numRegExStr + r'\)'),
      rotateRegEx = new RegExp(r'rotate\(' + numRegExStr + r'(deg)?\)'),
      skewRegEx = new RegExp(r'skewX\(' + numRegExStr + r'(deg)?\)'),
      translateA = translateRegEx.firstMatch(a),
      scaleA = scaleRegEx.firstMatch(a),
      rotateA = rotateRegEx.firstMatch(a),
      skewA = skewRegEx.firstMatch(a),
      translateB = translateRegEx.firstMatch(b),
      scaleB = scaleRegEx.firstMatch(b),
      rotateB = rotateRegEx.firstMatch(b),
      skewB = skewRegEx.firstMatch(b);

  var numSetA = [], numSetB = [], tempStr, match;

  // translate
  if (translateA != null) {
    tempStr = a.substring(translateA.start, translateA.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetA.add(num.parse(m.group(0)));
    }
  } else {
    numSetA.addAll(const [0, 0]);
  }

  if (translateB != null) {
    tempStr = b.substring(translateB.start, translateB.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetB.add(num.parse(m.group(0)));
    }
  } else {
    numSetB.addAll(const [0, 0]);
  }

  // scale
  if (scaleA != null) {
    tempStr = a.substring(scaleA.start, scaleA.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetA.add(num.parse(m.group(0)));
    }
  } else {
    numSetA.addAll(const [1, 1]);
  }

  if (scaleB != null) {
    tempStr = b.substring(scaleB.start, scaleB.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetB.add(num.parse(m.group(0)));
    }
  } else {
    numSetB.addAll(const [1, 1]);
  }

  // rotate
  if (rotateA != null) {
    tempStr = a.substring(rotateA.start, rotateA.end);
    match = numberRegEx.firstMatch(tempStr);
    numSetA.add(num.parse(match.group(0)));
  } else {
    numSetA.add(0);
  }

  if (rotateB != null) {
    tempStr = b.substring(rotateB.start, rotateB.end);
    match = numberRegEx.firstMatch(tempStr);
    numSetB.add(num.parse(match.group(0)));
  } else {
    numSetB.add(0);
  }

  // rotate < 180 degree
  if (numSetA[4] != numSetB[4]) {
    if (numSetA[4] - numSetB[4] > 180) {
      numSetB[4] += 360;
    } else if (numSetB[4] - numSetA[4] > 180) {
      numSetA[4] += 360;
    }
  }

  // skew
  if (skewA != null) {
    tempStr = a.substring(skewA.start, skewA.end);
    match = numberRegEx.firstMatch(tempStr);
    numSetA.add(num.parse(match.group(0)));
  } else {
    numSetA.add(0);
  }

  if (skewB != null) {
    tempStr = b.substring(skewB.start, skewB.end);
    match = numberRegEx.firstMatch(tempStr);
    numSetB.add(num.parse(match.group(0)));
  } else {
    numSetB.add(0);
  }

  return (t) {
    return 'translate(${createNumberInterpolator(numSetA[0], numSetB[0])(t)},'
        '${createNumberInterpolator(numSetA[1], numSetB[1])(t)})'
        'scale(${createNumberInterpolator(numSetA[2], numSetB[2])(t)},'
        '${createNumberInterpolator(numSetA[3], numSetB[3])(t)})'
        'rotate(${createNumberInterpolator(numSetA[4], numSetB[4])(t)})'
        'skewX(${createNumberInterpolator(numSetA[5], numSetB[5])(t)})';
  };
}

/// Returns the interpolator that interpolators zoom list [a] to [b]. Zoom
/// lists are described by triple elements [ux0, uy0, w0] and [ux1, uy1, w1].
Interpolator createZoomInterpolator(List a, List b) {
  if (a == null || b == null) return (t) => b;
  assert(a.length == b.length && a.length == 3);

  var sqrt2 = math.SQRT2, param2 = 2, param4 = 4;

  var ux0 = a[0], uy0 = a[1], w0 = a[2], ux1 = b[0], uy1 = b[1], w1 = b[2];

  var dx = ux1 - ux0,
      dy = uy1 - uy0,
      d2 = dx * dx + dy * dy,
      d1 = math.sqrt(d2),
      b0 = (w1 * w1 - w0 * w0 + param4 * d2) / (2 * w0 * param2 * d1),
      b1 = (w1 * w1 - w0 * w0 - param4 * d2) / (2 * w1 * param2 * d1),
      r0 = math.log(math.sqrt(b0 * b0 + 1) - b0),
      r1 = math.log(math.sqrt(b1 * b1 + 1) - b1),
      dr = r1 - r0,
      S = ((!dr.isNaN) ? dr : math.log(w1 / w0)) / sqrt2;

  return (t) {
    var s = t * S;
    if (!dr.isNaN) {
      // General case.
      var coshr0 = cosh(r0),
          u = w0 / (param2 * d1) * (coshr0 * tanh(sqrt2 * s + r0) - sinh(r0));
      return [ux0 + u * dx, uy0 + u * dy, w0 * coshr0 / cosh(sqrt2 * s + r0)];
    }
    // Special case for u0 ~= u1.
    return [ux0 + t * dx, uy0 + t * dy, w0 * math.exp(sqrt2 * s)];
  };
}

/// Reverse interpolator for a number.
Interpolator uninterpolateNumber(num a, num b) {
  b = 1 / (b - a);
  return (x) => (x - a) * b;
}

/// Reverse interpolator for a clamped number.
Interpolator uninterpolateClamp(num a, num b) {
  b = 1 / (b - a);
  return (x) => math.max(0, math.min(1, (x - a) * b));
}
