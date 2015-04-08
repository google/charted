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

/// Fix direction of text using unicode markers for RTL when required
fixTextDirection(String text) => _bidiFormatter.wrapWithUnicode(text);

/// Fix direction of HTML using <span dir="..."> for RTL when required
fixMarkupDirection(String markup) =>
    _bidiFormatter.wrapWithSpan(markup, isHtml:true);
