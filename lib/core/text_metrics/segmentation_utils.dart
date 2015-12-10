//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.core.text_metrics.segmentation_utils;

const CODE_CATEGORY_OTHER = 0;

const CodeUnitCategory = const {
  'Other': CODE_CATEGORY_OTHER,
  'CR': 1,
  'LF': 2,
  'Control': 3,
  'Extend': 4,
  'SpacingMark': 5,
  'L': 6,
  'V': 7,
  'T': 8,
  'LV': 9,
  'LVT': 10,
  'Regional_Indicator': 11
};
