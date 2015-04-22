//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.utils;

/// Charts are always drawn with LTR context.
BidiFormatter _bidiFormatter = new BidiFormatter.LTR();

/// Fix direction of HTML using <span dir="..."> for RTL when required
fixMarkupDirection(String markup) =>
    _bidiFormatter.wrapWithSpan(markup, isHtml:true);

/// Fix direction of text using unicode markers for RTL when required
/// This is a simplified version of BidiFormatter.wrapWithUnicode that
/// is meant to be used for small labels only (Eg: axis ticks).
String fixSimpleTextDirection(String text) {
  TextDirection direction = estimateDirectionOfSimpleText(text);
  if (TextDirection.RTL == direction) {
    var result = text;
    var marker = direction == TextDirection.RTL ? Bidi.RLE : Bidi.LRE;
    return "${marker}$text${Bidi.PDF}";
  }
  return text;
}

/// Estimates direction of simple text.
/// This is a simplified version of Bidi.estimateDirectionOfText
var _spaceRegExp = new RegExp(r'\s+');
var _digitsRegExp = new RegExp(r'\d');
TextDirection estimateDirectionOfSimpleText(String text) {
  var rtlCount = 0,
      total = 0,
      hasWeaklyLtr = false,
      tokens = text.split(_spaceRegExp);

  for (int i = 0, len = tokens.length; i < len; ++i) {
    var token = tokens.elementAt(i);
    if (Bidi.startsWithRtl(token)) {
      rtlCount++;
      total++;
    } else if (Bidi.hasAnyLtr(token)) {
      total++;
    } else if (_digitsRegExp.hasMatch(token)) {
      hasWeaklyLtr = true;
    }
  }
  if (total == 0) {
    return hasWeaklyLtr ? TextDirection.LTR : TextDirection.UNKNOWN;
  } else {
    return rtlCount > 0.4 * total ? TextDirection.RTL : TextDirection.LTR;
  }
}
