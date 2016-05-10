/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.locale.format;

typedef String TimeFormatFunction(DateTime date);

//TODO(songrenchu): Document time format; Add test for time format.

class TimeFormat {
  String _template;
  String _locale;
  DateFormat _dateFormat;

  TimeFormat([String template = null, String identifier = 'en_US']) {
    _template = template;
    _locale = identifier;
    if (_template != null) _dateFormat =
        new DateFormat(_wrapStrptime2ICU(_template), _locale);
  }

  TimeFormat _getInstance(String template) {
    return new TimeFormat(template, _locale);
  }

  String apply(DateTime date) {
    assert(_dateFormat != null);
    return _dateFormat.format(date);
  }

  String toString() => _template;

  DateTime parse(String string) {
    assert(_dateFormat != null);
    return _dateFormat.parse(string);
  }

  TimeFormatFunction multi(List<List> formats) {
    var n = formats.length, i = -1;
    while (++i < n) formats[i][0] = _getInstance(formats[i][0] as String);
    return (var date) {
      if (date is num) {
        date = new DateTime.fromMillisecondsSinceEpoch((date as num).toInt());
      }
      var i = 0, f = formats[i];
      while (f.length < 2 || f[1](date) == false) {
        i++;
        if (i < n) f = formats[i];
      }
      if (i == n) return null;
      return f[0].apply(date);
    };
  }

  UTCTimeFormat utc([String specifier = null]) {
    return new UTCTimeFormat(
        specifier == null ? _template : specifier, _locale);
  }

  static UTCTimeFormat iso() {
    return new UTCTimeFormat("%Y-%m-%dT%H:%M:%S.%LZ");
  }

  static Map timeFormatPads = {"-": "", "_": " ", "0": "0"};
  // TODO(songrenchu): Cannot fully be equivalent now.
  static Map timeFormatsTransform = {
    'a': 'EEE',
    'A': 'EEEE',
    'b': 'MMM',
    'B': 'MMMM',
    'c': 'EEE MMM d HH:mm:ss yyyy',
    'd': 'dd',
    'e': 'd', // TODO(songrenchu): zero padding not supported
    'H': 'HH',
    'I': 'hh',
    'j': 'DDD',
    'm': 'MM',
    'M': 'mm',
    'L': 'SSS',
    'p': 'a',
    'S': 'ss',
    'U': 'ww', // TODO(songrenchu): ICU doesn't distinguish 'U' and 'W',
    // and not supported by Dart: DateFormat
    'w': 'ee', // TODO(songrenchu): e not supported by Dart: DateFormat
    'W': 'ww', // TODO(songrenchu): ICU doesn't distinguish 'U' and 'W',
    // and not supported by Dart: DateFormat
    'x': 'MM/dd/yyyy',
    'X': 'HH:mm:ss',
    'y': 'yy',
    'Y': 'yyyy',
    'Z': 'Z',
    '%': '%'
  };

  String _wrapStrptime2ICU(String template) {
    var string = [], i = -1, j = 0, n = template.length, tempChar;
    while (++i < n) {
      if (template[i] == '%') {
        string.add(template.substring(j, i));
        if ((timeFormatPads[tempChar = template[++i]]) != null) tempChar =
            template[++i];
        if (timeFormatsTransform[tempChar] != null) string
            .add(timeFormatsTransform[tempChar]);
        j = i + 1;
      }
    }
    if (j < i) string.add("'" + template.substring(j, i) + "'");
    return string.join("");
  }
}

class UTCTimeFormat extends TimeFormat {
  UTCTimeFormat(String template, [String identifier = 'en_US'])
      : super(template, identifier);

  UTCTimeFormat _getInstance(String template) {
    return new UTCTimeFormat(template, _locale);
  }

  DateTime parse(String string) {
    assert(_dateFormat != null);
    return _dateFormat.parseUTC(string);
  }
}
