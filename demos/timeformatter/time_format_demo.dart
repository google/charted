/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
library charted.charts_demo;
import 'dart:html';
import "package:charted/locale/locale.dart";

void main() {
  Locale locale = new EnusLocale();

  // Whole test without time zone (not implemented yet)
  TimeFormat format = locale.timeFormat(
      '%a; %A; %b; %B; %c; %d; %e; %H; %I; %j; %m; %M;'
      ' %L; %p; %S; %U; %w; %W; %x; %X; %y; %Y; %%');
  querySelector('#format-all').text =
    format.apply(new DateTime(2014, 3, 9, 18, 23, 45, 67));

  // parse
  format = locale.timeFormat("%Y-%m-%d");
  querySelector('#format-1').text =
    format.parse("2012-10-12").toString();

  // multi
  var multiFormat = locale.timeFormat().multi([
    [".%L", (d) => (d as DateTime).millisecond > 0],
    [":%S", (d) => (d as DateTime).second > 0],
    ["%Y",  (d) => true]
  ]);
  querySelector('#format-2').text =
    multiFormat(new DateTime(2014, 1, 1, 1, 1, 30, 123));
  querySelector('#format-3').text =
    multiFormat(new DateTime(2014, 1, 1, 1, 1, 30));
  querySelector('#format-4').text =
    multiFormat(new DateTime(2014));

  // iso
  var iso = TimeFormat.iso();
  querySelector('#format-5').text =
    iso.apply(new DateTime.now());

  // utc
  var utc = locale.timeFormat().utc("%Y-%m-%d %H:%M:%S");
  querySelector('#format-6').text =
    utc.apply(new DateTime.now());
}