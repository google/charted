/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
/*
 * TODO(midoringo,prsd): Document library
 */
library charted.charts;

import 'dart:async';
import 'dart:collection';
import 'dart:html' show Element,document,window;
import 'dart:math' as math;
import 'dart:svg';
import 'dart:typed_data';

@MirrorsUsed()
import 'dart:mirrors' show MirrorsUsed;

import 'package:charted/core/core.dart';
import 'package:charted/layout/layout.dart';
import 'package:charted/locale/locale.dart';
import 'package:charted/scale/scale.dart';
import 'package:charted/selection/selection.dart';
import 'package:charted/svg/svg.dart';
import 'package:charted/transition/transition.dart';
import 'package:collection/equality.dart';
import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:quiver/iterables.dart';
import 'package:quiver/strings.dart';

part 'chart_axis.dart';
part 'chart_area.dart';
part 'chart_config.dart';
part 'chart_data.dart';
part 'chart_legend.dart';
part 'chart_renderer.dart';
part 'chart_series.dart';
part 'chart_theme.dart';

part 'renderers/bar_chart_renderer.dart';
part 'renderers/line_chart_renderer.dart';
part 'renderers/pie_chart_renderer.dart';
part 'renderers/spark_chart_renderer.dart';
part 'renderers/stackedbar_chart_renderer.dart';

part 'transformers/aggregation.dart';
part 'transformers/aggregation_item.dart';
part 'transformers/aggregation_transformer.dart';
part 'transformers/transformer.dart';

part 'src/chart_area_impl.dart';
part 'src/chart_axis_impl.dart';
part 'src/chart_config_impl.dart';
part 'src/chart_data_impl.dart';
part 'src/chart_legend_impl.dart';
part 'src/chart_series_impl.dart';

part 'themes/quantum_theme.dart';

final Logger logger = new Logger('charted.charts');

class SubscriptionsDisposer {
  List<StreamSubscription> _subscriptions = [];
  Expando<StreamSubscription> _byObject = new Expando();

  void add(StreamSubscription value, [Object handle]) {
    if (handle != null) _byObject[handle] = value;
    _subscriptions.add(value);
  }

  void unsubscribe(Object handle) {
    StreamSubscription s = _byObject[handle];
    if (s != null) {
      _subscriptions.remove(s);
      s.cancel();
    }
  }

  void dispose() {
    _subscriptions.forEach((StreamSubscription val) {
      if (val != null) val.cancel();
    });
    _subscriptions.clear();
  }
}
