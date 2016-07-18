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
import 'package:charted/selection/selection.dart';

///
/// [SvgAxis] helps draw chart axes based on a given scale.
///
class SvgAxis {
  /// Store of axis roots mapped to currently used scales
  static final _scales = new Expando<Scale>();

  /// Orientation of the axis. Defaults to [ORIENTATION_BOTTOM].
  final String orientation;

  /// Scale used on this axis
  final Scale scale;

  /// Size of all inner ticks
  final num innerTickSize;

  /// Size of the outer two ticks
  final num outerTickSize;

  /// Padding on the ticks
  final num tickPadding;

  /// List of values to be used on the ticks
  List _tickValues;

  /// Formatter for the tick labels
  FormatFunction _tickFormat;

  SvgAxis(
      {this.orientation: ORIENTATION_BOTTOM,
      this.innerTickSize: 6,
      this.outerTickSize: 6,
      this.tickPadding: 3,
      Iterable tickValues,
      FormatFunction tickFormat,
      Scale scale})
      : scale = scale == null ? new LinearScale() : scale {
    _tickFormat =
        tickFormat == null ? this.scale.createTickFormatter() : tickFormat;
    _tickValues = isNullOrEmpty(tickValues) ? this.scale.ticks : tickValues;
  }

  Iterable get tickValues => _tickValues;

  FormatFunction get tickFormat => _tickFormat;

  /// Draw an axis on each non-null element in selection
  draw(Selection g, {SvgAxisTicks axisTicksBuilder, bool isRTL: false}) =>
      g.each((d, i, e) =>
          create(e, g.scope, axisTicksBuilder: axisTicksBuilder, isRTL: isRTL));

  /// Create an axis on [element].
  create(Element element, SelectionScope scope,
      {SvgAxisTicks axisTicksBuilder, bool isRTL: false}) {
    var group = scope.selectElements([element]),
        older = _scales[element],
        current = _scales[element] = scale.clone(),
        isInitialRender = older == null;

    var isLeft = orientation == ORIENTATION_LEFT,
        isRight = !isLeft && orientation == ORIENTATION_RIGHT,
        isVertical = isLeft || isRight,
        isBottom = !isVertical && orientation == ORIENTATION_BOTTOM,
        isTop = !(isVertical || isBottom) && orientation == ORIENTATION_TOP,
        isHorizontal = !isVertical;

    if (older == null) older = current;
    if (axisTicksBuilder == null) {
      axisTicksBuilder = new SvgAxisTicks();
    }
    axisTicksBuilder.init(this);

    var values = axisTicksBuilder.ticks,
        formatted = axisTicksBuilder.formattedTicks,
        ellipsized = axisTicksBuilder.shortenedTicks;

    var ticks = group.selectAll('.tick').data(values, current.scale),
        exit = ticks.exit,
        transform = isVertical ? _yAxisTransform : _xAxisTransform,
        sign = isTop || isLeft ? -1 : 1,
        isEllipsized = ellipsized != formatted;

    var enter = ticks.enter.appendWithCallback((d, i, e) {
      var group = Namespace.createChildElement('g', e)
        ..append(Namespace.createChildElement('line', e))
        ..append(Namespace.createChildElement('text', e)
          ..attributes['dy'] =
              isVertical ? '0.32em' : (isBottom ? '0.71em' : '0'));
      if (!isInitialRender) {
        group.style.setProperty('opacity', EPSILON.toString());
      }
      return group;
    });

    // All attributes/styles/classes that may change due to theme and scale.
    // TODO(prsd): Order elements before updating ticks.
    ticks.each((d, i, e) {
      e.attributes['class'] = 'tick tick-$i';
      Element line = e.firstChild;
      Element text = e.lastChild;
      bool isRTLText = false; // FIXME(prsd)

      if (isHorizontal) {
        line.attributes['y2'] = '${sign * innerTickSize}';
        text.attributes['y'] =
            '${sign * (math.max(innerTickSize, 0) + tickPadding)}';

        if (axisTicksBuilder.rotation != 0) {
          text.attributes
            ..['transform'] =
                'rotate(${(isRTL ? -1 : 1) * axisTicksBuilder.rotation})'
            ..['text-anchor'] = isRTL ? 'end' : 'start';
        } else {
          text.attributes
            ..remove('transform')
            ..['text-anchor'] = 'middle';
        }
      } else {
        line.attributes['x2'] = '${sign * innerTickSize}';
        text.attributes
          ..['x'] = '${sign * (math.max(innerTickSize, 0) + tickPadding)}'
          ..['text-anchor'] = isLeft
              ? (isRTLText ? 'start' : 'end')
              : (isRTLText ? 'end' : 'start');
      }

      text.text = fixSimpleTextDirection(ellipsized.elementAt(i));
      if (isEllipsized) {
        text.attributes['data-detail'] = formatted.elementAt(i);
      } else {
        text.attributes.remove('data-detail');
      }

      if (isInitialRender) {
        var dx = current is OrdinalScale ? current.rangeBand / 2 : 0;
        e.attributes['transform'] = isHorizontal
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
    var path = element.querySelector('.domain'),
        tickSize = sign * outerTickSize,
        range = current.rangeExtent;
    if (path == null) {
      path = Namespace.createChildElement('path', element)
        ..setAttribute('class', 'domain');
    }
    path.attributes['d'] = isLeft || isRight
        ? 'M${tickSize},${range.min}H0V${range.max}H${tickSize}'
        : 'M${range.min},${tickSize}V0H${range.max}V${tickSize}';
    element.append(path);
  }

  _xAxisTransform(Selection selection, transformFn) {
    selection.transition()
      ..attrWithCallback(
          'transform', (d, i, e) => 'translate(${transformFn(d)},0)');
  }

  _yAxisTransform(Selection selection, transformFn) {
    selection.transition()
      ..attrWithCallback(
          'transform', (d, i, e) => 'translate(0,${transformFn(d)})');
  }
}

/// Interface and the default implementation of [SvgAxisTicks].
/// SvgAxisTicks provides strategy to handle overlapping ticks on an
/// axis.  Default implementation assumes that the ticks don't overlap.
class SvgAxisTicks {
  int _rotation = 0;
  Iterable _ticks;
  Iterable _formattedTicks;

  void init(SvgAxis axis) {
    _ticks = axis.tickValues;
    _formattedTicks = _ticks.map((x) => axis.tickFormat(x));
  }

  /// When non-zero, indicates the angle by which each tick value must be
  /// rotated to avoid the overlap.
  int get rotation => _rotation;

  /// List of ticks that will be displayed on the axis.
  Iterable get ticks => _ticks;

  /// List of formatted ticks values.
  Iterable get formattedTicks => _formattedTicks;

  /// List of clipped tick values, if they had to be clipped. Must be same
  /// as the [formattedTicks] if none of the ticks were ellipsized.
  Iterable get shortenedTicks => _formattedTicks;
}
