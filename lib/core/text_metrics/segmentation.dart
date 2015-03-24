//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.core.text_metrics.segmentation;

import "package:collection/algorithms.dart";
import "package:charted/core/text_metrics/segmentation_utils.dart";
import "package:charted/core/text_metrics/segmentation_data.dart";

/// Current unicode version.
/// Character database available at http://www.unicode.org/Public/7.0.0/ucd/
const UNICODE_VERSION = '7.0.0';

// Code table based on:
// http://www.unicode.org/Public/7.0.0/ucd/auxiliary/GraphemeBreakTest.html
// GRAPHEME_BREAK_TABLE[previousTypeIndex][currentTypeIndex] == 1 means break.
const GRAPHEME_BREAK_TABLE = const[
  const[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1],
  const[1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  const[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  const[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1],
  const[1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1],
  const[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0]
];

int _typeForRune(int rune) {
  int position = binarySearch(CODE_POINT_BLOCKS, rune,
      compare: (CodeRange a, int value) =>
          a.start <= value && value <= a.end ? 0 : a.start.compareTo(value));
  return position == -1
      ? CODE_CATEGORY_OTHER
      : CODE_POINT_BLOCKS[position].codePointType;
}

Iterable<int> graphemeBreakIndices(String s) {
  Runes runes = s.runes;
  List<int> indices = [];
  int previousTypeIndex = 0;
  for (int i = 0, len = runes.length; i < len; ++i) {
    int currentTypeIndex = _typeForRune(runes.elementAt(i));
    if (GRAPHEME_BREAK_TABLE[previousTypeIndex][currentTypeIndex] == 1) {
      indices.add(i);
    }
  }
  return indices;
}
