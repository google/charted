/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.locale;

// Defines the en_us locale and related format properties.
class EnusLocale extends Locale {
  get identifier => 'en_US';
  get decimal => '.';
  get thousands => ',';
  get grouping => [3];
  get currency => ['\$', ''];
  get dateTime => '%a %b %e %X %Y';
  get date => '%m/%d/%Y';
  get time => '%H =>%M =>%S';
  get periods => ['AM', 'PM'];
  get days => ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  get shortDays => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  get months => ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  get shortMonths => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}
