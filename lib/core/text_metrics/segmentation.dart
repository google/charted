//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.core.text_metrics.segmentation;

import "package:charted/core/text_metrics/segmentation_utils.dart";
import "package:charted/core/text_metrics/segmentation_data.dart";

/// Current unicode version.
/// Character database available at http://www.unicode.org/Public/7.0.0/ucd/
const UNICODE_VERSION = '7.0.0';

// Code table based on:
// http://www.unicode.org/Public/7.0.0/ucd/auxiliary/GraphemeBreakTest.html
// GRAPHEME_BREAK_TABLE[prevType * TYPE_COUNT + curType] == 1 means break.
const GRAPHEME_BREAK_TABLE = const [
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  1,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  1,
  0,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  0
];

/// Get type of a given char code.
int _typeForRune(int rune) {
  int count = CODE_POINT_BLOCKS.length ~/ 3;
  int min = 0;
  int max = count - 1;
  while (max >= min) {
    int mid = (max + min) ~/ 2;
    int idx = mid * 3;
    if (CODE_POINT_BLOCKS[idx] <= rune && rune <= CODE_POINT_BLOCKS[idx + 1]) {
      return CODE_POINT_BLOCKS[idx + 2]; // Return the found character type
    }
    if (CODE_POINT_BLOCKS[idx] > rune) {
      max = mid - 1;
    } else if (CODE_POINT_BLOCKS[idx + 1] < rune) {
      min = max + 1;
    }
  }
  return CODE_CATEGORY_OTHER; // Defaults to OTHER.
}

List<int> graphemeBreakIndices(String s) {
  List<int> indices = [];
  int previousType = 0;
  for (var iter = s.runes.iterator; iter.moveNext();) {
    int currentType = _typeForRune(iter.current);
    if (GRAPHEME_BREAK_TABLE[previousType * 12 + currentType] == 1) {
      indices.add(iter.rawIndex);
    }
    previousType = currentType;
  }
  return indices;
}
