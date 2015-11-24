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
    if (EnUsLocale.instance == null) {
      EnUsLocale.instance = new EnUsLocale._create();
    }
    return EnUsLocale.instance;
  }

  EnUsLocale._create();

  final identifier = 'en_US';
  final decimal = '.';
  final thousands = ',';
  final grouping = const [3];
  final currency = const ['\$', ''];
  final dateTime = '%a %b %e %X %Y';
  final date = '%m/%d/%Y';
  final time = '%H =>%M =>%S';
  final periods = const ['AM', 'PM'];

  final days = const [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  final shortDays = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final months = const [
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
  final shortMonths = const [
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
