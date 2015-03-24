/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

class Color {
  int r;
  int g;
  int b;
  double a;

  Color.fromHex(String hex, [this.a = 1.0]) {
   var rgb = _hexToRgb(hex);
   r = rgb[0];
   g = rgb[1];
   b = rgb[2];
  }

  Color.fromRgb(this.r, this.g, this.b, [this.a = 1.0]);

  List _hexToRgb(String hex) {
    List rgb = [];

    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 3) {
      // expand to 6-digit hex code
      hex = hex[0]*2 + hex[1]*2 + hex[2]*2;
    }
    rgb.add(int.parse(hex.substring(0, 2), radix: 16));
    rgb.add(int.parse(hex.substring(2, 4), radix: 16));
    rgb.add(int.parse(hex.substring(4, 6), radix: 16));
    return rgb;
  }

  Color.fromColorString(String color) {
    // TODO(midoringo): add rgba
    if (color.startsWith('#')) {
      var rgb = _hexToRgb(color);
      r = rgb[0];
      g = rgb[1];
      b = rgb[2];
      a = 1.0;
    } else if (color.startsWith('rgb')) {
      var numberRegEx = new RegExp(
          r'rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)');
      var match = numberRegEx.firstMatch(color);
      r = int.parse(match.group(1));
      g = int.parse(match.group(2));
      b = int.parse(match.group(3));
      a = 1.0;
    } else {
      r = g = b = 0;
      a = 1.0;
    }
  }

  String get rgbString => "rgb($r,$g,$b)";

  String get rgbaString => "rgba($r,$g,$b,$a)";

  String get hexString => '#' + _hexify(r) + _hexify(g) + _hexify(b);

  String toString() => rgbString;

  String _hexify(int v) {
    return v < 0x10
        ? "0" + math.max(0, v).toInt().toRadixString(16)
        : math.min(255, v).toInt().toRadixString(16);
  }

  static bool isColorString(String input) {
    return (input.startsWith('#') || input.startsWith('rgb'));
  }
  
  bool operator ==(other) {
    if (other is! Color) return false;
    Color color = other;
    return r == color.r && g == color.g && b == color.b && a == color.a;
  }

  // Override hashCode using strategy from Effective Java, Chapter 3.
  int get hashCode {
    int result = 17;
    result = 37 * result + r.hashCode;
    result = 37 * result + g.hashCode;
    result = 37 * result + b.hashCode;
    result = 37 * result + a.hashCode;
    return result;
  }
}

