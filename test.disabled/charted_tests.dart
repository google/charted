/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test;

import 'charts/transformers/transformer_test.dart' as transformer;
import 'charts/renderers/renderer_test.dart' as renderer;
import 'core/core_test.dart' as core;
import 'event/event_test.dart' as event;
import 'format/format_test.dart' as format;
import 'interpolators/interpolators_test.dart' as interpolators;
import 'layout/layout_test.dart' as layout;
import 'locale/locale_test.dart' as locale;
import 'scale/scale_test.dart' as scale;
import 'selection/selection_test.dart' as selection;
import 'svg/svg_test.dart' as svg;
import 'time/time_test.dart' as time;
import 'transition/transition_test.dart' as transition;

allChartedTests() {
  core.coreTests();
  event.eventTests();
  format.formatTests();
  interpolators.interpolatorsTests();
  layout.layoutTests();
  locale.localeTests();
  renderer.rendererTests();
  scale.scaleTests();
  selection.selectionTests();
  svg.svgTests();
  time.timeTests();
  transition.transitionTests();
  transformer.transformerTests();
}
