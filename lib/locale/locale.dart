//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.locale;

import 'package:charted/locale/format.dart';

part 'languages/en_us.dart';

abstract class Locale {
  String get identifier;
  String get decimal;
  String get thousands;
  List<int> get grouping;
  List<String> get currency;

  String get dateTime;
  String get date;
  String get time;
  List<String> get periods;

  List<String> get days;
  List<String> get shortDays;

  List<String> get months;
  List<String> get shortMonths;

  Locale();

  NumberFormat get numberFormat => new NumberFormat(this);

  TimeFormat timeFormat([String specifier]) =>
      new TimeFormat(specifier, this.identifier);
}
