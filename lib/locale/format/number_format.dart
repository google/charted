/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.locale.format;

/**
 * The number formatter of a given locale.  Applying the locale specific
 * number format, number grouping and currency symbol, etc..  The format
 * function in the NumberFormat class is used to format a number by the given
 * specifier with the number properties of the locale.
 */
class NumberFormat {
  // [[fill]align][sign][symbol][0][width][,][.precision][type]
  static RegExp FORMAT_REGEX = new RegExp(
      r'(?:([^{])?([<>=^]))?([+\- ])?([$#])?(0)?(\d+)?(,)?'
      r'(\.-?\d+)?([a-z%])?',
      caseSensitive: false);

  String localeDecimal;
  String localeThousands;
  List localeGrouping;
  List localeCurrency;
  Function formatGroup;

  NumberFormat(Locale locale) {
    localeDecimal = locale.decimal;
    localeThousands = locale.thousands;
    localeGrouping = locale.grouping;
    localeCurrency = locale.currency;
    formatGroup = (localeGrouping != null)
        ? (value) {
            var i = value.length, t = [], j = 0, g = localeGrouping[0];
            while (i > 0 && g > 0) {
              if (i - g >= 0) {
                i = i - g;
              } else {
                g = i;
                i = 0;
              }
              var length = (i + g) < value.length ? (i + g) : value.length;
              t.add(value.substring(i, length));
              g = localeGrouping[j = (j + 1) % localeGrouping.length];
            }
            return t.reversed.join(localeThousands);
          }
        : (x) => x;
  }

  /**
   * Returns a new format function with the given string specifier. A format
   * function takes a number as the only argument, and returns a string
   * representing the formatted number. The format specifier is modeled after
   * Python 3.1's built-in format specification mini-language. The general form
   * of a specifier is:
   * [​[fill]align][sign][symbol][0][width][,][.precision][type].
   *
   * @see <a href="http://docs.python.org/release/3.1.3/library/string.html#formatspec">format specification mini-language</a>
   */
  FormatFunction format(String specifier) {
    Match match = FORMAT_REGEX.firstMatch(specifier);
    var fill = match.group(1) != null ? match.group(1) : ' ',
        align = match.group(2) != null ? match.group(2) : '>',
        sign = match.group(3) != null ? match.group(3) : '',
        symbol = match.group(4) != null ? match.group(4) : '',
        zfill = match.group(5),
        width = match.group(6) != null ? int.parse(match.group(6)) : 0,
        comma = match.group(7) != null,
        precision =
        match.group(8) != null ? int.parse(match.group(8).substring(1)) : null,
        type = match.group(9),
        scale = 1,
        prefix = '',
        suffix = '',
        integer = false;

    if (zfill != null || fill == '0' && align == '=') {
      zfill = fill = '0';
      align = '=';
      if (comma) {
        width -= ((width - 1) / 4).floor();
      }
    }

    switch (type) {
      case 'n':
        comma = true;
        type = 'g';
        break;
      case '%':
        scale = 100;
        suffix = '%';
        type = 'f';
        break;
      case 'p':
        scale = 100;
        suffix = '%';
        type = 'r';
        break;
      case 'b':
      case 'o':
      case 'x':
      case 'X':
        if (symbol == '#') prefix = '0' + type.toLowerCase();
        break;
      case 'c':
      case 'd':
        integer = true;
        precision = 0;
        break;
      case 's':
        scale = -1;
        type = 'r';
        break;
    }

    if (symbol == '\$') {
      prefix = localeCurrency[0];
      suffix = localeCurrency[1];
    }

    // If no precision is specified for r, fallback to general notation.
    if (type == 'r' && precision == null) {
      type = 'g';
    }

    // Ensure that the requested precision is in the supported range.
    if (precision != null) {
      if (type == 'g') {
        precision = math.max(1, math.min(21, precision));
      } else if (type == 'e' || type == 'f') {
        precision = math.max(0, math.min(20, precision));
      }
    }

    NumberFormatFunction formatFunction = _getFormatFunction(type);

    var zcomma = (zfill != null) && comma;

    return (value) {
      if (value == null) return '-';
      var fullSuffix = suffix;

      // Return the empty string for floats formatted as ints.
      if (integer && (value % 1) > 0) return '';

      // Convert negative to positive, and record the sign prefix.
      var negative;
      if (value < 0 || value == 0 && 1 / value < 0) {
        value = -value;
        negative = '-';
      } else {
        negative = sign;
      }

      // Apply the scale, computing it from the value's exponent for si
      // format.  Preserve the existing suffix, if any, such as the
      // currency symbol.
      if (scale < 0) {
        FormatPrefix unit =
            new FormatPrefix(value, (precision != null) ? precision : 0);
        value = unit.scale(value);
        fullSuffix = unit.symbol + suffix;
      } else {
        value *= scale;
      }

      // Convert to the desired precision.
      if (precision != null) {
        value = formatFunction(value, precision);
      } else {
        value = formatFunction(value);
      }

      // Break the value into the integer part (before) and decimal part
      // (after).
      var i = value.lastIndexOf('.'),
          before = i < 0 ? value : value.substring(0, i),
          after = i < 0 ? '' : localeDecimal + value.substring(i + 1);

      // If the fill character is not '0', grouping is applied before
      //padding.
      if (zfill == null && comma) {
        before = formatGroup(before);
      }

      int length = prefix.length +
          before.length +
          after.length +
          (zcomma ? 0 : negative.length);
      var padding = length < width
          ? new List.filled((length = width - length + 1), '').join(fill)
          : '';

      // If the fill character is '0', grouping is applied after padding.
      if (zcomma) {
        before = formatGroup(padding + before);
      }

      // Apply prefix.
      negative += prefix;

      // Rejoin integer and decimal parts.
      value = before + after;

      // Apply any padding and alignment attributes before returning the string.
      return (align == '<'
              ? negative + value + padding
              : align == '>'
                  ? padding + negative + value
                  : align == '^'
                      ? padding.substring(0, length >>= 1) +
                          negative +
                          value +
                          padding.substring(length)
                      : negative + (zcomma ? value : padding + value)) +
          fullSuffix;
    };
  }

  // Gets the format function by given type.
  NumberFormatFunction _getFormatFunction(String type) {
    switch (type) {
      case 'b':
        return (num x, [int p = 0]) => x.toInt().toRadixString(2);
      case 'c':
        return (num x, [int p = 0]) => new String.fromCharCodes([x]);
      case 'o':
        return (num x, [int p = 0]) => x.toInt().toRadixString(8);
      case 'x':
        return (num x, [int p = 0]) => x.toInt().toRadixString(16);
      case 'X':
        return (num x, [int p = 0]) =>
            x.toInt().toRadixString(16).toUpperCase();
      case 'g':
        return (num x, [int p = 1]) => x.toStringAsPrecision(p);
      case 'e':
        return (num x, [int p = 0]) => x.toStringAsExponential(p);
      case 'f':
        return (num x, [int p = 0]) => x.toStringAsFixed(p);
      case 'r':
      default:
        return (num x, [int p = 0]) => x.toString();
    }
  }
}
