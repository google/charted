//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.svg.axis;

import 'dart:html' show Element, window;
import 'dart:math' as math;

import 'package:charted/core/scales.dart';
import 'package:charted/core/utils.dart';
import 'package:charted/core/text_metrics.dart';
import 'package:charted/selection/selection.dart';

///
/// [SvgAxs] helps draw chart axes based on a given scale.
///
class SvgAxis {
  /// Orientation of the axis. Defaults to [ORIENTATION_BOTTOM].
  final String orientation;

  final bool isLeft;
  final bool isRight;
  final bool isTop;
  final bool isBottom;

  /// Scale used on this axis
  Scale scale = new LinearScale();

  /// Size of all inner ticks
  num innerTickSize = 6;

  /// Size of the outer two ticks
  num outerTickSize = 6;

  /// Padding on the ticks
  num tickPadding = 3;

  /// List of values to be used on the ticks
  List tickValues;

  /// Formatter for the tick labels
  FormatFunction tickFormat;

  /// Store of axis roots mapped to currently used scales
  static Expando<Scale> _scales = new Expando<Scale>();

  SvgAxis(String orientation)
      : orientation = orientation == null ? ORIENTATION_BOTTOM : orientation,
        isLeft = orientation == ORIENTATION_LEFT,
        isRight = orientation == ORIENTATION_RIGHT,
        isTop = orientation == ORIENTATION_TOP,
        isBottom = orientation == ORIENTATION_BOTTOM;

  /// Draw an axis on each non-null element in selection
  draw(Selection g, { Rect rect, String font, isRTL: false }) =>
          g.each((d, i, e) =>
              create(e, g.scope, rect:rect, font:font, isRTL:isRTL));

  /// Create an axis on [element]. Uses [scope] to save the data associations.
  create(Element element,
      SelectionScope scope, {Rect rect, String font, bool isRTL}) {

    var group = scope.selectElements([element]),
        older = _scales[element],
        current = _scales[element] = scale.clone(),
        isInitialRender = older == null;    // Drawing axis first time.

    older = older == null ? current : older;

    var tickFormat = this.tickFormat == null
            ? current.createTickFormatter()
            : this.tickFormat,
        tickValues = this.tickValues == null ? current.ticks : this.tickValues,
        formatted = tickValues.map((x) => tickFormat(x)).toList(),
        range = current.rangeExtent;

    // When ticks don't have enough space on the horizontal axes, they are first
    // rotated by 45deg. Then, if required, they are clipped.
    bool rotateTicks = false;
    if ((isBottom || isTop) && rect != null && !isNullOrEmpty(font)) {
      var textMetrics = new TextMetrics(fontStyle: font);
      var allowedWidth = (range.max - range.min) ~/ formatted.length;
      var maxLabelWidth = textMetrics.getLongestTextWidth(formatted);

      // Check if we need rotation
      if (0.90 * allowedWidth < maxLabelWidth) {
        rotateTicks = true;

        // Check if we have enough space to render full chart
        allowedWidth = (1.4142 * rect.height) - (textMetrics.fontSize / 1.4142);
        if (maxLabelWidth > allowedWidth) {
          for (int i = 0; i < formatted.length; ++i) {
            formatted[i] = textMetrics.ellipsizeText(formatted[i], allowedWidth);
          }
        }
      }
    }

    var ticks = group.selectAll('.tick').data(tickValues, current.scale),
        exit = ticks.exit,
        transform = isLeft || isRight ? _yAxisTransform : _xAxisTransform,
        convert = isTop || isLeft ? -1 : 1;

    // For entering ticks, add the line and text element for label.
    // Only attributes that are constant and solely depend on orientation
    // are set here.
    var enter = ticks.enter.appendWithCallback((d, i, e) {
      var group = Namespace.createChildElement('g', e)
        ..classes.add('tick')
        ..append(Namespace.createChildElement('line',  e))
        ..append(Namespace.createChildElement('text', e)
            ..attributes['dy'] = isLeft || isRight
                ? '0.32em'
                : isBottom ? '0.71em' : '0');
      if (!isInitialRender) {
        group.style.setProperty('opacity', EPSILON.toString());
      }
      return group;
    });

    // All attributes/styles/classes that may change due to theme and scale.
    ticks.each((d, i, e) {
      Element line = e.firstChild;
      Element text = e.lastChild;
      bool isRTLText = false; // FIXME(prsd)

      if (isBottom || isTop) {
        line.attributes['y2'] = (convert * innerTickSize).toString();
        text.attributes['y'] =
            (convert * (math.max(innerTickSize, 0) + tickPadding)).toString();

        if (rotateTicks) {
          text.attributes
            ..['transform'] = 'rotate(${isRTL ? -45 : 45})'
            ..['text-anchor'] = isRTL ? 'end' : 'start';
        } else {
          text.attributes
            ..['transform'] = ''
            ..['text-anchor'] = 'middle';
        }
      } else {
        line.attributes['x2'] = (convert * innerTickSize).toString();
        text.attributes
            ..['x'] = '${convert * (math.max(innerTickSize, 0) + tickPadding)}'
            ..['text-anchor'] = isLeft
                ? (isRTLText ? 'start' : 'end')
                : (isRTLText ? 'end' : 'start');
      }

      text.text = fixSimpleTextDirection(formatted[i]);

      if (isInitialRender) {
        var dx = current is OrdinalScale ? current.rangeBand / 2 : 0;
        e.attributes['transform'] = isTop || isBottom
            ? 'translate(${current.scale(d) + dx},0)'
            : 'translate(0,${current.scale(d) + dx})';
      } else {
        e.style.setProperty('opacity', '1.0');
      }
    });

    // Transition existing ticks to right positions
    if (!isInitialRender) {
      var transformFn;
      if (current is OrdinalScale && current.rangeBand != 0) {
        var dx = current.rangeBand / 2;
        transformFn = (d) => current.scale(d) + dx;
      } else if (older is OrdinalScale && older.rangeBand != 0) {
        older = current;
      } else {
        transform(ticks, current.scale);
      }

      transform(enter, transformFn != null ? transformFn : older.scale);
      transform(ticks, transformFn != null ? transformFn : current.scale);
    }

    exit.remove();

    // Append the outer domain.
    var path = element.querySelector('.domain');
    if (path == null) {
      path = Namespace.createChildElement('path', element);
      path.classes.add('domain');
    }
    var tickSize = convert * outerTickSize;
    path.attributes['d'] = isLeft || isRight
        ? 'M${tickSize},${range.min}H0V${range.max}H${tickSize}'
        : 'M${range.min},${tickSize}V0H${range.max}V${tickSize}';
    element.append(path);
  }

  _xAxisTransform(Selection selection, transformFn) {
    selection.transition()
      ..attrWithCallback(
          'transform', (d, i, e) => 'translate(${transformFn(d)},0)');
    selection.transition()
      ..style('opacity', '1.0')
      ..delay(50);
  }

  _yAxisTransform(Selection selection, transformFn) {
    selection.transition()
      ..attrWithCallback(
          'transform', (d, i, e) => 'translate(0,${transformFn(d)})');
    selection.transition()
      ..style('opacity', '1.0')
      ..delay(50);
  }
}
