/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.svg;

typedef String Formatter(x);

/**
 * [SvgAxis] helps draw chart axes based on a given scale.
 */
class SvgAxis {
  /** Scale used on this axis */
  Scale scale = new LinearScale();

  /** Orientation of the axis.  Defaults to [ORIENTATION_BOTTOM] */
  String orientation = ORIENTATION_BOTTOM;

  /** Size of all inner ticks */
  num innerTickSize = 6;

  /** Size of the outer two ticks */
  num outerTickSize = 6;

  /** Padding on the ticks */
  num tickPadding = 3;

  /** Suggested number of ticks to be displayed on the axis */
  num suggestedTickCount = 10;

  /** List of values to be used on the ticks */
  List tickValues;

  /** Formatter for the tick labels */
  Formatter tickFormat;

  /** Previous rotate angle */
  num _prevRotate = 0;

  /* Store of axis roots mapped to currently used scales */
  static Expando<Scale> _scales = new Expando<Scale>();

  axis(Selection g) => g.each((d, i, e) => _create(e, g.scope));

  _create(Element e, SelectionScope scope) {
    var group = scope.selectElements([e]),
        older = _scales[e],
        current = _scales[e] = scale.clone();

    if (older == null) older = scale;
    var tickFormat = this.tickFormat == null ?
            current.tickFormatter() : this.tickFormat,
        tickValues = this.tickValues == null ?
            current.ticks(suggestedTickCount) : this.tickValues;

    var ticks = group.selectAll('.tick').data(tickValues, current.scale),
        tickEnter = ticks.enter.insert('g', before:'.domain')
            ..classed('tick')
            ..style('opacity', EPSILON.toString()),
        tickExit = ticks.exit..remove(),
        tickUpdate = ticks..style('opacity', '1'),
        tickTransform;

    var range = current.rangeExtent,
        path = group.selectAll('.domain').data([0]);
        path.enter.append('path');
        path.attr('class', 'domain');

    tickEnter.append('line');
    tickEnter.append('text');

    var lineEnter = tickEnter.select('line'),
        lineUpdate = tickUpdate.select('line'),
        textEnter = tickEnter.select('text'),
        textUpdate = tickUpdate.select('text'),
        text = ticks.select('text')
            ..textWithCallback((d,i,e) => tickFormat(d));

    switch (orientation) {
      case ORIENTATION_BOTTOM: {
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
      }
        break;
      case ORIENTATION_TOP: {
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
      }
        break;
      case ORIENTATION_LEFT: {
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
      }
      break;
      case ORIENTATION_RIGHT: {
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
      }
      break;
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
