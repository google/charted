//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.charts;

import 'dart:async';
import 'dart:collection';
import 'dart:html' show Element, window, Event, MouseEvent;
import 'dart:math' as math;
import 'dart:svg' hide Rect;
import 'dart:typed_data';

import 'package:charted/core/text_metrics.dart';
import 'package:charted/core/utils.dart';
import 'package:charted/core/scales.dart';
import 'package:charted/core/interpolators.dart';
import 'package:charted/layout/layout.dart';
import 'package:charted/selection/selection.dart';
import 'package:charted/svg/axis.dart';
import 'package:charted/svg/shapes.dart';
import 'package:charted/selection/transition.dart';

import 'package:collection/equality.dart';
import 'package:logging/logging.dart';
import 'package:observable/observable.dart';
import 'package:quiver/core.dart';

part 'chart_area.dart';
part 'chart_config.dart';
part 'chart_data.dart';
part 'chart_events.dart';
part 'chart_legend.dart';
part 'chart_renderer.dart';
part 'chart_series.dart';
part 'chart_state.dart';
part 'chart_theme.dart';

part 'behaviors/axis_label_tooltip.dart';
part 'behaviors/chart_tooltip.dart';
part 'behaviors/hovercard.dart';
part 'behaviors/line_marker.dart';
part 'behaviors/mouse_tracker.dart';

part 'cartesian_renderers/bar_chart_renderer.dart';
part 'cartesian_renderers/cartesian_base_renderer.dart';
part 'cartesian_renderers/bubble_chart_renderer.dart';
part 'cartesian_renderers/line_chart_renderer.dart';
part 'cartesian_renderers/stackedbar_chart_renderer.dart';

part 'layout_renderers/layout_base_renderer.dart';
part 'layout_renderers/pie_chart_renderer.dart';

part 'src/cartesian_area_impl.dart';
part 'src/layout_area_impl.dart';
part 'src/chart_axis_impl.dart';
part 'src/chart_config_impl.dart';
part 'src/chart_data_impl.dart';
part 'src/chart_events_impl.dart';
part 'src/chart_legend_impl.dart';
part 'src/chart_series_impl.dart';
part 'src/chart_state_impl.dart';

part 'themes/quantum_theme.dart';

part 'data_transformers/aggregation.dart';
part 'data_transformers/aggregation_item.dart';
part 'data_transformers/aggregation_transformer.dart';
part 'data_transformers/filter_transformer.dart';
part 'data_transformers/transpose_transformer.dart';

final Logger logger = new Logger('charted.charts');
