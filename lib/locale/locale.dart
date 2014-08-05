/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
/*
 * TODO(midoringo): Document library
 */
library charted.locale;

import 'dart:math' as math;
import 'package:charted/core/core.dart';
import 'package:charted/format/format.dart';
import 'package:charted/time/time.dart' as chartTime;
import 'package:charted/scale/scale.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:charted/interpolators/interpolators.dart' as interpolators;

part 'en_us.dart';
part 'number_format.dart';
part 'time_format.dart';
part 'time_scale.dart';

abstract class Locale {
  String get identifier;
  String get decimal;
  String get thousands;
  List get grouping;
  List get currency;
  String get dateTime;
  String get date;
  String get time;
  List get periods;
  List get days;
  List get shortDays;
  List get months;
  List get shortMonths;

  Locale() {
    initializeDateFormatting(this.identifier, null);
  }

  NumberFormat get numberFormat => new NumberFormat(this);
  // TODO(songrenchu): port time format.
  TimeFormat timeFormat([specifier = null]) =>
    new TimeFormat(specifier, this.identifier);

}
