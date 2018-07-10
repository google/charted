/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.locale.format;

//TODO(songrenchu): Document time format; Add test for time format.

class TimeFormat {
  final String _template;
  final String _locale;
  final DateFormat _dateFormat;

  TimeFormat([String template, String identifier = 'en_US'])
      : _template = template,
        _locale = identifier,
        _dateFormat = template == null
            ? null
            : new DateFormat(_wrapStrptime2ICU(template), identifier);

  String apply(DateTime date) {
    assert(_dateFormat != null);
    return _dateFormat.format(date);
  }

  String toString() => _template;

  DateTime parse(String string) {
    assert(_dateFormat != null);
    return _dateFormat.parse(string);
  }

  FormatFunction multi(List<List> formats) {
    var n = formats.length, i = -1;
    while (++i < n) {
      formats[i][0] = new TimeFormat(formats[i][0] as String, _locale);
    }
    return (dynamic _date) {
      DateTime date = _date is DateTime
          ? _date
          : new DateTime.fromMillisecondsSinceEpoch((_date as num).toInt());
      var i = 0, f = formats[i];
      while (f.length < 2 || !(f[1] as bool Function(DateTime))(date)) {
        i++;
        if (i < n) f = formats[i];
      }
      if (i == n) return null;
      return (f[0] as TimeFormat).apply(date);
    };
  }

  static const Map<String, String> _timeFormatPads = const {
    "-": "",
    "_": " ",
    "0": "0"
  };
  // TODO(songrenchu): Cannot fully be equivalent now.
  static const Map<String, String> _timeFormatsTransform = const {
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

  static String _wrapStrptime2ICU(String template) {
    List<String> string = [];
    int i = -1, j = 0, n = template.length;
    while (++i < n) {
      if (template[i] == '%') {
        string.add(template.substring(j, i));
        String ch = template[++i];
        if ((_timeFormatPads[ch]) != null) ch = template[++i];
        if (_timeFormatsTransform[ch] != null)
          string.add(_timeFormatsTransform[ch]);
        j = i + 1;
      }
    }
    if (j < i) string.add("'${template.substring(j, i)}'");
    return string.join();
  }
}
