/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.interpolators;

/** Returns a numeric interpolator between numbers [a] and [b] */
InterpolateFn interpolateNumber(num a, num b) {
  b -= a;
  return (t) => a + b * t;
}

/** Returns a rounded number interpolator between numbers [a] and [b] */
InterpolateFn interpolateRound(num a, num b) {
  b -= a;
  return (t) => (a + b * t).round();
}

/**
 * Returns the interpolator between two strings [a] and [b].
 *
 * The interpolator will interpolate all the number pairs in both strings
 * that have same number of numeric parts.  The function assumes the non
 * number part of the string to be identical and would use string [b] for
 * merging the non numeric part of the strings.
 *
 * Eg: Interpolate between $100.0 and $150.0
 */
InterpolateFn interpolateString(String a, String b) {
  if (a == null || b == null) return (t) => b;
  if (Color.isColorString(a) && Color.isColorString(b)) {
    return interpolateColor(new Color.fromColorString(a),
              new Color.fromColorString(b));
  }
  var numberRegEx =
          new RegExp(r'[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?'),
      numMatchesInA = numberRegEx.allMatches(a),
      numMatchesInB = numberRegEx.allMatches(b),
      stringParts = [],
      numberPartsInA = [],
      numberPartsInB = [],
      interpolators = [],
      s0 = 0;

  // Get all the non number parts in a.
  numberPartsInA.addAll(numMatchesInA.map((m) => m.group(0)));

  // Get all the non number parts in b and record string parts.
  for (Match m in numMatchesInB) {
    stringParts.add(b.substring(s0, m.start));
    numberPartsInB.add(m.group(0));
    s0 = m.end;
  }

  if (s0 < b.length) stringParts.add(b.substring(s0));

  int numberLength = math.min(numberPartsInA.length, numberPartsInB.length);
  int maxLength = math.max(numberPartsInA.length, numberPartsInB.length);
  for (var i = 0; i < numberLength; i++) {
    interpolators.add(interpolateNumber(num.parse(numberPartsInA[i]),
        num.parse(numberPartsInB[i])));
  }
  if (numberPartsInA.length < numberPartsInB.length) {
    for (var i = numberLength; i < maxLength; i++) {
      interpolators.add(interpolateNumber(num.parse(numberPartsInB[i]),
        num.parse(numberPartsInB[i])));
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

/** Returns the interpolator for RGB values. */
InterpolateFn interpolateColor(Color a, Color b) {
  if (a == null || b == null) return (t) => b;
  var ar = a.r,
      ag = a.g,
      ab = a.b,
      br = b.r - ar,
      bg = b.g - ag,
      bb = b.b - ab;

  return (t) => new Color.fromRgb(
      (ar + br * t).round(), (ag + bg * t).round(), (ab + bb * t).round());
}

/** Returns the interpolator using HSL color system converted to Hex string. */
InterpolateFn interpolateHsl(a, b) {
  if (a == null || b == null) return (t) => b;
  if (a is String && Color.isColorString(a)) a = new Color.fromColorString(a);
  if (a is Color) a = new cssParser.Hsla.fromString(a.hexString);
  if (b is String && Color.isColorString(b)) b = new Color.fromColorString(b);
  if (b is Color) b = new cssParser.Hsla.fromString(b.hexString);

  var ah = a.hue,
      as = a.saturation,
      al = a.lightness,
      bh = b.hue - ah,
      bs = b.saturation - as,
      bl = b.lightness - al;

  return (t) => "#" + new cssParser.Hsla(
      ah + bh * t, as + bs * t, al + bl * t).toHexArgbString();
}

/**
 * Returns the interpolator that interpolators each element between lists
 * [a] and [b] using registered interpolators.
 */
InterpolateFn interpolateList(List a, List b) {
  if (a == null || b == null) return (t) => b;
  var x = [],
      na = a.length,
      nb = b.length,
      n0 = math.min(na, nb),
      c = new List.filled(math.max(na, nb), null),
      i;

  for (i = 0; i < n0; i++) x.add(interpolator(a[i], b[i]));
  for (; i < na; ++i) c[i] = a[i];
  for (; i < nb; ++i) c[i] = b[i];

  return (t) {
    for (i = 0; i < n0; ++i) c[i] = x[i](t);
    return c;
  };
}

/**
 * Returns the interpolator that interpolators each element between maps
 * [a] and [b] using registered interpolators.
 */
InterpolateFn interpolateMap(Map a, Map b) {
  if (a == null || b == null) return (t) => b;
  var x = new Map(),
      c = new Map(),
      ka = a.keys.toList(),
      kb = b.keys.toList();

  ka.forEach((k) {
    if (b[k] != null) x[k] = (interpolator(a[k], b[k]));
    else c[k] = a[k];
  });
  kb.forEach((k) {
    if (c[k] == null) c[k] = b[k];
  });

  return (t) {
    x.forEach((k, v) => c[k] = v(t));
    return c;
  };
}

InterpolateFn uninterpolateNumber(num a, num b) {
  b = 1 / (b - a);
  return (x) => (x - a) * b;
}

InterpolateFn uninterpolateClamp(num a, num b) {
  b = 1 / (b - a);
  return (x) => math.max(0, math.min(1, (x - a) * b));
}

/**
 * Returns the interpolator that interpolators two transform strings
 * [a] and [b] by their translate, rotate, scale and skewX parts.
 */
InterpolateFn interpolateTransform(String a, String b) {
  if (a == null || b == null) return (t) => b;
  var numRegExStr = r'[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?',
      translateRegExStr =
          r'translate\(' + numRegExStr + r',' + numRegExStr + r'\)',
      scaleRegExStr = r'scale\(' + numRegExStr + r',' + numRegExStr + r'\)',
      rotateRegExStr = r'rotate\(' + numRegExStr + r'(deg)?\)',
      skewRegExStr = r'skewX\(' + numRegExStr + r'(deg)?\)',

      numberRegEx = new RegExp(numRegExStr),
      translateRegEx = new RegExp(translateRegExStr),
      scaleRegEx = new RegExp(scaleRegExStr),
      rotateRegEx = new RegExp(rotateRegExStr),
      skewRegEx = new RegExp(skewRegExStr),

      translateA = translateRegEx.firstMatch(a),
      scaleA = scaleRegEx.firstMatch(a),
      rotateA = rotateRegEx.firstMatch(a),
      skewA = skewRegEx.firstMatch(a),

      translateB = translateRegEx.firstMatch(b),
      scaleB = scaleRegEx.firstMatch(b),
      rotateB = rotateRegEx.firstMatch(b),
      skewB = skewRegEx.firstMatch(b);

  var numSetA = [],
      numSetB = [],
      tempStr, match;

  // translate
  if (translateA != null) {
    tempStr = a.substring(translateA.start, translateA.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetA.add(num.parse(m.group(0)));
    }
  } else {
    numSetA.addAll(const[0, 0]);
  }

  if (translateB != null) {
    tempStr = b.substring(translateB.start, translateB.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetB.add(num.parse(m.group(0)));
    }
  } else {
    numSetB.addAll(const[0, 0]);
  }

  // scale
  if (scaleA != null) {
    tempStr = a.substring(scaleA.start, scaleA.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetA.add(num.parse(m.group(0)));
    }
  } else {
    numSetA.addAll(const[1, 1]);
  }

  if (scaleB != null) {
    tempStr = b.substring(scaleB.start, scaleB.end);
    match = numberRegEx.allMatches(tempStr);
    for (Match m in match) {
      numSetB.add(num.parse(m.group(0)));
    }
  } else {
    numSetB.addAll(const[1, 1]);
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
    return "translate("+
        interpolateNumber(numSetA[0], numSetB[0])(t).toString()+"," +
        interpolateNumber(numSetA[1], numSetB[1])(t).toString()+")scale("+
        interpolateNumber(numSetA[2], numSetB[2])(t).toString()+","+
        interpolateNumber(numSetA[3], numSetB[3])(t).toString()+")rotate("+
        interpolateNumber(numSetA[4], numSetB[4])(t).toString()+")skewX("+
        interpolateNumber(numSetA[5], numSetB[5])(t).toString()+")";
  };
}

/**
 * Returns the interpolator that interpolators two Zoom lists [a] and [b].
 * [a] and [b] are described by triple elements
 * [ux0, uy0, w0] and [ux1, uy1, w1].
 */
InterpolateFn interpolateZoom(List a, List b) {
  if (a == null || b == null) return (t) => b;
  assert(a.length == b.length && a.length == 3);

  var sqrt2 = math.SQRT2,
      param2 = 2,
      param4 = 4;

  var ux0 = a[0], uy0 = a[1], w0 = a[2],
      ux1 = b[0], uy1 = b[1], w1 = b[2];

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
      return [
        ux0 + u * dx,
        uy0 + u * dy,
        w0 * coshr0 / cosh(sqrt2 * s + r0)
      ];
    }
    // Special case for u0 ~= u1.
    return [
      ux0 + t * dx,
      uy0 + t * dy,
      w0 * math.exp(sqrt2 * s)
    ];
  };
}
