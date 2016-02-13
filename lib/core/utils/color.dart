//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.utils;

/// Represents a single color for use in visualizations.  Currently, supports
/// representing and conversion between RGB, RGBA, HSL, HSLA and hex formats.
class Color {
  // Internal representation of RGB
  int _r = 0;
  int _g = 0;
  int _b = 0;

  // Internal representation of HSL
  int _h = 0; // 0 <= _h <= 360
  int _s = 0; // 0 <= _s <= 100
  int _l = 0; // 0 <= _l <= 100

  // Alpha value for this color
  double _a = 0.0;

  // Flags to indicate the color-space for which values are readily available.
  bool _hasRgbColors = false;
  bool _hasHslColors = false;

  /// Create an instance from RGB colors.
  Color.fromRgba(this._r, this._g, this._b, this._a) : _hasRgbColors = true;

  /// Create an instance using a string representing color in RGB color space.
  /// The input string, [value], can be one of the following formats:
  ///
  ///    #RGB
  ///    #RRGGBB
  ///
  ///    rgb(R, G, B)
  ///    rgba(R, G, B, A)
  ///
  /// R, G and B represent intensities of Red, Green and Blue channels and A
  /// represents the alpha channel (transparency)
  ///
  /// When using these formats:
  ///     0 <= R,G,B <= 255
  ///     0 <= A <= 1.0
  factory Color.fromRgbString(String value) =>
      isHexColorString(value) ? _fromHexString(value) : _fromRgbString(value);

  /// Create an instance from HSL colors.
  Color.fromHsla(this._h, this._s, this._l, this._a) : _hasHslColors = true;

  /// Create an instance using a string representing color in HSL color space.
  /// The input string, [value], can be in one of the following formats:
  ///
  ///     hsl(H, S%, L%)
  ///     hsla(H, S%, L%, A)
  ///
  /// H, S and L represent Hue, Saturation and Luminosity respectively.
  ///
  /// When using these formats:
  ///     0 <= H <= 360
  ///     0 <= S,L <= 100
  ///     0 <= A <= 1.0
  factory Color.fromHslString(String value) => _fromHslString(value);

  /// Ensures that the RGB values are available. If they aren't already
  /// available, they are computed from the HSA values.
  ///
  /// Based on color.js from Google Closure library
  void toRgb() {
    if (_hasRgbColors) return;

    num _hueToRgb(num v1, num v2, num vH) {
      vH %= 1.0;

      if ((6 * vH) < 1) {
        return (v1 + (v2 - v1) * 6 * vH);
      } else if (2 * vH < 1) {
        return v2;
      } else if (3 * vH < 2) {
        return (v1 + (v2 - v1) * ((2 / 3) - vH) * 6);
      }
      return v1;
    }

    final h = _h / 360;

    if (_s == 0) {
      _r = _g = _b = (_l * 255).round();
    } else {
      var temp1 = 0;
      var temp2 = 0;
      if (_l < 0.5) {
        temp2 = _l * (1 + _s);
      } else {
        temp2 = _l + _s - (_s * _l);
      }
      temp1 = 2 * _l - temp2;
      _r = (255 * _hueToRgb(temp1, temp2, h + (1 / 3))).round();
      _g = (255 * _hueToRgb(temp1, temp2, h)).round();
      _b = (255 * _hueToRgb(temp1, temp2, h - (1 / 3))).round();
    }
  }

  /// Ensures that the HSA values are available. If they aren't already
  /// available, they are computed from the RGB values.
  ///
  /// Based on color.js in Google Closure library.
  void toHsl() {
    if (_hasHslColors) return;

    final r = _r / 255;
    final g = _g / 255;
    final b = _b / 255;
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));

    double l = (max + min) / 2;
    double h = 0.0;
    double s = 0.0;

    // If max and min are equal, the color is gray (h = s = 0)
    if (max != min) {
      if (max == r) {
        h = 60 * (g - b) / (max - min);
      } else if (max == g) {
        h = 60 * (b - r) / (max - min) + 120;
      } else if (max == b) {
        h = 60 * (r - g) / (max - min) + 240;
      }

      if (0 < l && l <= 0.5) {
        s = (max - min) / (2 * l);
      } else {
        s = (max - min) / (2 - 2 * l);
      }
    }

    _h = (h % 360).floor();
    _s = (s * 100).floor();
    _l = (l * 100).floor();
  }

  /// Returns a hex string of the format '#RRGGBB' representing this color.
  /// A new string will be returned each time this function is called.
  String toHexString() {
    toRgb();
    return rgbToHexString(_r, _g, _b);
  }

  /// Returns a string similar to 'rgba(r, g, b, a)' representing this color.
  /// A new string will be returned each time this function is called.
  String toRgbaString() {
    toRgb();
    return 'rgba($_r,$_g,$_b,$_a)';
  }

  /// Returns a string similar to 'hsla(h, s, l, a)' representing this color.
  /// A new string will be returned each time this function is called.
  String toHslaString() {
    toHsl();
    return 'hsla($_h,$_s%,$_l%,$_a)';
  }

  /// Intensity of red from RGB.
  /// Computes RGB values if they are not already available.
  int get r {
    toRgb();
    return _r;
  }

  /// Intensity of green from RGB
  /// Computes RGB values if they are not already available.
  int get g {
    toRgb();
    return _g;
  }

  /// Intensity of blue from RGB.
  /// Computes RGB values if they are not already available.
  int get b {
    toRgb();
    return _b;
  }

  /// Hue value from HSL representation.
  /// Computes HSL values if they are not already available.
  int get h {
    toHsl();
    return _h;
  }

  /// Saturation value from HSL representation.
  /// Computes HSL values if they are not already available.
  int get s {
    toHsl();
    return _s;
  }

  /// Luminosity value from HSL representation.
  /// Computes HSL values if they are not already available.
  int get l {
    toHsl();
    return _l;
  }

  /// Alpha value used by both RGB and HSL representations.
  double get a => _a;

  @override
  String toString() => _hasRgbColors ? toRgbaString() : toHslaString();

  @override
  int get hashCode => toString().hashCode;

  /// Given RGB values create hex string from it.
  static String rgbToHexString(int r, int g, int b) {
    String _hexify(int v) {
      return v < 0x10
          ? "0" + math.max(0, v).toInt().toRadixString(16)
          : math.min(255, v).toInt().toRadixString(16);
    }
    return '#${_hexify(r)}${_hexify(g)}${_hexify(b)}';
  }

  /// RegExp to test if a given string is a hex color string
  static final RegExp hexColorRegExp =
      new RegExp(r'^#([0-9a-f]{3}){1,2}$', caseSensitive: false);

  /// Tests if [str] is a hex color
  static bool isHexColorString(String str) => hexColorRegExp.hasMatch(str);

  /// RegExp to test if a given string is rgb() or rgba() color.
  static final RegExp rgbaColorRegExp = new RegExp(
      r'^(rgb|rgba)?\(\d+,\s?\d+,\s?\d+(,\s?(0|1)?(\.\d)?\d*)?\)$',
      caseSensitive: false);

  /// Tests if [str] is a color represented by rgb() or rgba() or hex string
  static bool isRgbColorString(String str) =>
      isHexColorString(str) || rgbaColorRegExp.hasMatch(str);

  /// RegExp to test if a given string is hsl() or hsla() color.
  static final RegExp hslaColorRegExp = new RegExp(
      r'^(hsl|hsla)?\(\d+,\s?\d+%,\s?\d+%(,\s?(0|1)?(\.\d)?\d*)?\)$',
      caseSensitive: false);

  /// Tests if [str] is a color represented by hsl() or hsla()
  static bool isHslColorString(String str) => hslaColorRegExp.hasMatch(str);

  /// Create an instance using the passed RGB string.
  static Color _fromRgbString(String value) {
    int pos = (value.startsWith('rgb(') || value.startsWith('RGB('))
        ? 4
        : (value.startsWith('rgba(') || value.startsWith('RGBA(')) ? 5 : 0;
    if (pos != 0) {
      final params = value.substring(pos, value.length - 1).split(',');
      int r = int.parse(params[0]),
          g = int.parse(params[1]),
          b = int.parse(params[2]);
      double a = params.length == 3 ? 1.0 : double.parse(params[3]);
      return new Color.fromRgba(r, g, b, a);
    }
    return new Color.fromRgba(0, 0, 0, 0.0);
  }

  /// Create an instance using the passed HEX string.
  /// Assumes that the string starts with a '#' before HEX chars.
  static Color _fromHexString(String hex) {
    if (isNullOrEmpty(hex) || (hex.length != 4 && hex.length != 7)) {
      return new Color.fromRgba(0, 0, 0, 0.0);
    }
    int rgb = 0;

    hex = hex.substring(1);
    if (hex.length == 3) {
      for (int i = 0; i < hex.length; i++) {
        final val = int.parse(hex[i], radix: 16);
        rgb = (rgb * 16 + val) * 16 + val;
      }
    } else if (hex.length == 6) {
      rgb = int.parse(hex, radix: 16);
    }

    return new Color.fromRgba(
        (rgb & 0xff0000) >> 0x10, (rgb & 0xff00) >> 8, (rgb & 0xff), 1.0);
  }

  /// Create an instance using the passed HSL color string.
  static Color _fromHslString(String value) {
    int pos = (value.startsWith('hsl(') || value.startsWith('HSL('))
        ? 4
        : (value.startsWith('hsla(') || value.startsWith('HSLA(')) ? 5 : 0;
    if (pos != 0) {
      final params = value.substring(pos, value.length - 1).split(',');
      int h = int.parse(params[0]),
          s = int.parse(params[1]),
          l = int.parse(params[2]);
      double a = params.length == 3 ? 1.0 : double.parse(params[3]);
      return new Color.fromHsla(h, s, l, a);
    }
    return new Color.fromHsla(0, 0, 0, 0.0);
  }
}
