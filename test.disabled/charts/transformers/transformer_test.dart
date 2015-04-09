/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
library charted.transformer.test;

import 'aggregation_transformer_test.dart' as aggregation;
import 'chain_transform_test.dart' as chain;
import 'filter_transformer_test.dart' as filter;
import 'transpose_transformer_test.dart' as transpose;

transformerTests() {
  aggregation.main();
  chain.main();
  filter.main();
  transpose.main();
}

