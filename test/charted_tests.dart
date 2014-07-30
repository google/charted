/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test;

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

main(List<String> args) {
  core.main();
  event.main();
  format.main();
  interpolators.main();
  layout.main();
  locale.main();
  selection.main();
  scale.main();
  svg.main();
  time.main();
  transition.main();
}

