//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// Provides a way to measure rendered text width for clipping
/// text on tooltips and ticks when they are too long.
library charted.core.text_metrics;

import "dart:html";
import "package:charted/core/utils.dart";
import "package:charted/core/text_metrics/segmentation.dart";

class TextMetrics {
  static CanvasElement canvas;
  static CanvasRenderingContext2D context;
  static TextMetrics instance;

  static const MAX_STRING_LENGTH = 250;

  final String fontStyle;

  factory TextMetrics({String fontStyle}) {
    if (canvas == null || context == null) {
      canvas = document.createElement('canvas');
      context = canvas.getContext('2d');
    }
    if (instance == null) {
      instance = new TextMetrics._internal(fontStyle);
    }
    return instance;
  }
  TextMetrics._internal(this.fontStyle);

  double getTextWidth(String text, {String fontStyle}) {
    assert(text.length <= MAX_STRING_LENGTH);
    if (isNullOrEmpty(fontStyle)) {
      fontStyle = this.fontStyle;
    }
    context.font = fontStyle;
    return context.measureText(text).width;
  }

  double getLongestTextWidth(Iterable<String> strings, {String fontStyle}) {
    if (isNullOrEmpty(fontStyle)) {
      fontStyle = this.fontStyle;
    }
    context.font = fontStyle;

    double maxWidth = 0.0;
    for (int i = 0; i < strings.length; ++i) {
      assert(strings.elementAt(i).length <= MAX_STRING_LENGTH);
      double width = context.measureText(strings.elementAt(i)).width;
      if (width > maxWidth) {
        maxWidth = width;
      }
    }

    return maxWidth;
  }

  String ellipsizeText(String text, double width, {String fontStyle}) {
    assert(text.length <= MAX_STRING_LENGTH);
    if (isNullOrEmpty(fontStyle)) {
      fontStyle = this.fontStyle;
    }
    context.font = fontStyle;

    double computedWidth = context.measureText(text).width;
    if (computedWidth > width) {
      var breakIndices = graphemeBreakIndices(text),
          position = 0,
          min = 0, max = breakIndices.length, mid,
          ellipsis = context.measureText('…').width;
      width = width - ellipsis;
      while (min < max) {
        mid = (min + max) ~/ 2;
        position = breakIndices[mid];
        if (mid == min) break;
        if (context.measureText(text.substring(0, position)).width > width) {
          max = mid - 1;
        } else {
          min = mid;
        }
      }
      text = text.substring(0, breakIndices[mid - 1]) + '…';
    }
    return text;
  }

  /// Utility function to use an SVG text element API to ellipsize text.
  static ellipsizeTextElement() {
    /// TODO(prsd): Implement this.
  }
}
