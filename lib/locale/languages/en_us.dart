//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.locale;

// Defines the en_us locale and related format properties.
class EnUsLocale extends Locale {
  static EnUsLocale instance;

  factory EnUsLocale() {
    return instance ??= new EnUsLocale._();
  }

  EnUsLocale._();

  @override
  final String identifier = 'en_US';
  @override
  final String decimal = '.';
  @override
  final String thousands = ',';
  @override
  final List<int> grouping = const [3];
  @override
  final List<String> currency = const ['\$', ''];
  @override
  final String dateTime = '%a %b %e %X %Y';
  @override
  final String date = '%m/%d/%Y';
  @override
  final String time = '%H =>%M =>%S';
  @override
  final List<String> periods = const ['AM', 'PM'];

  @override
  final List<String> days = const [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  @override
  final List<String> shortDays = const [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  @override
  final List<String> months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  @override
  final List<String> shortMonths = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}
