/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
library charted.renderer.test;

import 'bar_chart_renderer_test.dart' as bar;
import 'line_chart_renderer_test.dart' as line;
import 'pie_chart_renderer_test.dart' as pie;
import 'stackedbar_chart_renderer_test.dart' as stacked_bar;

rendererTests() {
  bar.main();
  line.main();
  pie.main();
  stacked_bar.main();
}

