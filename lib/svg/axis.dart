//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.svg.axis;

import 'dart:html' show Element;
import 'dart:math' as math;

import 'package:charted/core/scales.dart';
import 'package:charted/core/utils.dart';
import 'package:charted/core/text_metrics.dart';
import 'package:charted/selection/selection.dart';

///
/// [SvgAxis] helps draw chart axes based on a given scale.
///
class SvgAxis {
  /// Scale used on this axis
  Scale scale = new LinearScale();

  /// Orientation of the axis.  Defaults to [ORIENTATION_BOTTOM].
  String orientation = ORIENTATION_BOTTOM;

  /// Size of all inner ticks
  num innerTickSize = 6;

  /// Size of the outer two ticks
  num outerTickSize = 6;

  /// Padding on the ticks
  num tickPadding = 3;

  /// Suggested number of ticks to be displayed on the axis
  num suggestedTickCount = 5;

  /// List of values to be used on the ticks
  List tickValues;

  /// Formatter for the tick labels
  FormatFunction tickFormat;

  /// Previous rotate angle
  num _prevRotate = 0;

  /// Store of axis roots mapped to currently used scales
  static Expando<Scale> _scales = new Expando<Scale>();

  draw(Selection g,
      {Rect rect, String font, bool preRender: false, isRTL: false}) =>
          g.each((d, i, e) =>
              _create(e, g.scope, rect, font, preRender, isRTL));

  _create(
      Element e,
      SelectionScope scope,
      Rect rect,
      String font,
      bool preRender,
      bool isRTL) {
    var group = scope.selectElements([e]),
        older = _scales[e],
        current = _scales[e] = scale.clone();

    if (older == null) older = scale;
    current.ticksCount = suggestedTickCount;

    var tickFormat = this.tickFormat == null
            ? current.createTickFormatter()
            : this.tickFormat,
        tickValues = this.tickValues == null ? current.ticks : this.tickValues,
        formatted = tickValues.map((x) => tickFormat(x)).toList();

    var range = current.rangeExtent == null && preRender == true
            ? new Extent(0, 1)
            : current.rangeExtent,
        path = group.selectAll('.domain').data([0]);
        path.enter.append('path');
        path.attr('class', 'domain');

    bool rotateTicks = false;
    if ((orientation == ORIENTATION_BOTTOM ||
            orientation == ORIENTATION_TOP) &&
        preRender != true && rect != null && !isNullOrEmpty(font)) {
      var textMetrics = new TextMetrics(fontStyle: font);
      var allowedWidth = (range.max - range.min) ~/ formatted.length;
      var maxLabelWidth = textMetrics.getLongestTextWidth(formatted);

      // Check if we need rotation
      if (0.90 * allowedWidth < maxLabelWidth) {
        rotateTicks = true;

        // Check if we have enough space to render full chart
        allowedWidth = 1.4142 * (rect.height - textMetrics.fontSize);
        if (maxLabelWidth > allowedWidth) {
          for (int i = 0; i < formatted.length; ++i) {
            formatted[i] = textMetrics.ellipsizeText(formatted[i], allowedWidth);
          }
        }
      }
    }

    var ticks = group.selectAll('.tick').data(tickValues, current.scale),
        tickEnter = ticks.enter.insert('g', before:'.domain')
            ..classed('tick')
            ..style('opacity', EPSILON.toString()),
        tickExit = ticks.exit..remove(),
        tickUpdate = ticks..style('opacity', '1'),
        tickTransform;

    var lineEnter = tickEnter.append('line'),
        lineUpdate = tickUpdate.select('line'),
        textEnter = tickEnter.append('text'),
        textUpdate = tickUpdate.select('text'),
        text = ticks.select('text')
            ..textWithCallback((d,i,e) => fixTextDirection(formatted[i]));

    switch (orientation) {
      case ORIENTATION_BOTTOM:
        tickTransform = _xAxisTransform;
        ticks.attr('y2', innerTickSize);
        lineEnter.attr('y2', innerTickSize);
        textEnter.attr('y', math.max(innerTickSize, 0) + tickPadding);
        lineUpdate
            ..attr('x2', 0)
            ..attr('y2', innerTickSize);
        textUpdate
            ..attr('x', 0)
            ..attr('y', math.max(innerTickSize, 0) + tickPadding);
        textEnter
            ..attr('dy', '.71em')
            ..style('text-anchor', 'middle');
        path.attr('d',
            'M${range.min},${outerTickSize}V0H${range.max}V${outerTickSize}');
        break;
      case ORIENTATION_TOP:
        tickTransform = _xAxisTransform;
        lineEnter.attr('y2', -innerTickSize);
        textEnter.attr('y', -(math.max(innerTickSize, 0) + tickPadding));
        lineUpdate
            ..attr('x2', 0)
            ..attr('y2', -innerTickSize);
        textUpdate
            ..attr('x', 0)
            ..attr('y', -(math.max(innerTickSize, 0) + tickPadding));
        textEnter
            ..attr('dy', '0em')
            ..style('text-anchor', 'middle');
        path.attr('d',
            'M${range.min},${-outerTickSize}V0H${range.max}V${-outerTickSize}');
        break;
      case ORIENTATION_LEFT:
        tickTransform = _yAxisTransform;
        lineEnter.attr('x2', -innerTickSize);
        textEnter.attr('x', -(math.max(innerTickSize, 0) + tickPadding));
        lineUpdate
            ..attr('x2', -innerTickSize)
            ..attr('y2', 0);
        textUpdate
            ..attr('x', -(math.max(innerTickSize, 0) + tickPadding))
            ..attr('y', 0);
        textEnter
            ..attr('dy', '.32em')
            ..style('text-anchor', 'end');
        path.attr('d',
            'M${-outerTickSize},${range.min}H0V${range.max}H${-outerTickSize}');
        break;
      case ORIENTATION_RIGHT:
        tickTransform = _yAxisTransform;
        lineEnter.attr('x2', innerTickSize);
        textEnter.attr('x', math.max(innerTickSize, 0) + tickPadding);
        lineUpdate
            ..attr('x2', innerTickSize)
            ..attr('y2', 0);
        textUpdate
            ..attr('x', math.max(innerTickSize, 0) + tickPadding)
            ..attr('y', 0);
        textEnter
            ..attr('dy', '.32em')
            ..style('text-anchor', 'start');
        path.attr('d',
            'M${outerTickSize},${range.min}H0V${range.max}H${outerTickSize}');
        break;
    }

    if (rotateTicks) {
      var angle = isRTL ? -45 : 45,
          textAnchor = isRTL ? 'end' : 'start';
      textUpdate
          ..attr('transform', 'rotate($angle)')
          ..style('text-anchor', textAnchor);
    } else {
      textUpdate
          ..attr('transform', '')
          ..style('text-anchor', 'middle');
    }

    // If either the new or old scale is ordinal,
    // entering ticks are undefined in the old scale,
    // and so can fade-in in the new scale’s position.
    // Exiting ticks are likewise undefined in the new scale,
    // and so can fade-out in the old scale’s position.
    var transformFn;
    if (current is OrdinalScale && current.rangeBand != 0) {
      var dx = current.rangeBand / 2;
      transformFn = (d) => current.scale(d) + dx;
    } else if (older is OrdinalScale && older.rangeBand != 0) {
      older = current;
    } else {
      tickTransform(tickExit, current.scale);
    }

    tickTransform(tickEnter, transformFn != null ? transformFn : older.scale);
    tickTransform(
        tickUpdate, transformFn != null ? transformFn : current.scale);
  }

  _xAxisTransform(selection, transformFn) {
    selection.attrWithCallback(
        'transform', (d, i, e) => 'translate(${transformFn(d)},0)'
    );
  }

  _yAxisTransform(selection, transformFn) {
    selection.attrWithCallback(
        'transform', (d, i, e) => 'translate(0,${transformFn(d)})'
    );
  }
}
