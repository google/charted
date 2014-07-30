/**
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
  /** Orientation for axis displayed on the left of chart */
  static const String ORIENTATION_LEFT = 'left';

  /** Orientation for axis displayed on the right of chart */
  static const String ORIENTATION_RIGHT = 'right';

  /** Orientation for axis displayed at the top of chart */
  static const String ORIENTATION_TOP = 'top';

  /** Orientation for axis displayed at the bottom of chart */
  static const String ORIENTATION_BOTTOM = 'bottom';

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
        current = _scales[e] = scale.copy();

    if (older == null) older = scale;
    var tickFormat = this.tickFormat == null ?
            current.tickFormat(suggestedTickCount) : this.tickFormat,
        tickValues = this.tickValues == null ?
            current.ticks(suggestedTickCount) : this.tickValues;

    var ticks = group.selectAll('.tick').data(tickValues, current.apply),
        tickEnter = ticks.enter.insert('g', before:'.domain')
            ..classed('tick')
            ..style('opacity', EPSILON.toString()),
        tickExit = ticks.exit..remove(),
        tickUpdate = ticks..style('opacity', '1'),
        tickTransform;

    var range = current.rangeExtent(),
        path = group.selectAll('.domain').data([0]);
        path.enter.append('path');
        path.attr('class', 'domain');

    num axisLength = range[1] - range[0];

    tickEnter.append('line');
    tickEnter.append('text');

    var lineEnter = tickEnter.select('line'),
        lineUpdate = tickUpdate.select('line'),
        textEnter = tickEnter.select('text'),
        textUpdate = tickUpdate.select('text'),
        text = ticks.select('text')
            ..textWithCallback((d,i,e) => tickFormat(d));

    var ellipsis = group.selectAll('.ellipsis').data(["... ..."]);
    ellipsis.enter.append('text')
        ..attr('class', 'ellipsis')
        ..style('text-anchor', 'middle')
        ..textWithCallback((d, i, e) => d)
        ..attr('opacity', 0);

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
        ellipsis
            ..attr('x', axisLength / 2)
            ..attr('y', '.71em');
        path.attr('d',
            'M${range[0]},${outerTickSize}V0H${range[1]}V${outerTickSize}');
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
        ellipsis
            ..attr('x', axisLength / 2)
            ..attr('y', 0);
        path.attr('d',
            'M${range[0]},${-outerTickSize}V0H${range[1]}V${-outerTickSize}');
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
        ellipsis
            ..attr("transform",
                "translate(${-tickPadding}, ${axisLength / 2})rotate(90)");
        path.attr('d',
            'M${-outerTickSize},${range[0]}H0V${range[1]}H${-outerTickSize}');
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
        ellipsis
            ..attr("transform",
                "translate(${tickPadding}, ${axisLength / 2})rotate(90)");
        path.attr('d',
            'M${outerTickSize},${range[0]}H0V${range[1]}H${outerTickSize}');
      }
      break;
    }

    num currentRotate = 0;
    num prevRotate = _prevRotate;

    lineEnter..attr('opacity', '0');
    textEnter..attr('opacity', '0');
    lineEnter.transition()
      ..attr('opacity', '1')
      ..delay(100);

    List textOpacity = new List.filled(text.length, 1);

    if (orientation == ORIENTATION_BOTTOM || orientation == ORIENTATION_TOP) {
      num maxTextWidth = 0,
          textHeight = text.first.clientHeight;
      text.each((d, i, e)
          => maxTextWidth = math.max(maxTextWidth, e.clientWidth));
      if (maxTextWidth > axisLength / text.length) currentRotate = 45;
      if (textHeight * 1.5 > axisLength / text.length) {
        currentRotate = 90;
      }
      _prevRotate = currentRotate;
      List preTransX = new List(),
           nowTransX = new List(),
           preTransY = new List(),
           nowTransY = new List();
      num prevArc = prevRotate * math.PI / 180,
          nowArc = currentRotate * math.PI / 180;
      text.each((d, i, e) {
        preTransX.add(prevRotate > 0 ?
            e.clientWidth * math.cos(prevArc) / 2 : 0);
        nowTransX.add(currentRotate > 0 ? e.clientWidth * math.cos(nowArc) / 2 : 0);
        preTransY.add(e.clientWidth * math.sin(prevArc) / 2);
        nowTransY.add(e.clientWidth * math.sin(nowArc) / 2);
      });
      text.transition()
          ..attrTween('transform', (d, i, e) {
            return interpolateTransform(
              "translate(${preTransX[i]},${preTransY[i]})rotate(${prevRotate})",
              "translate(${nowTransX[i]},${nowTransY[i]})rotate(${currentRotate})");
          })
          ..attr('dx', '${.71 * math.sin(nowArc)}em')
          ..attr('dy', '${.71 * math.cos(nowArc)}em');
      if (currentRotate == 90) {
        text.each((d, i, Element e) {
          if (i > 0 && i < text.length - 1) {
            textOpacity[i] = 0;
          }
          group.selectAll('.ellipsis').transition()
              ..delay(100)
              ..attr('opacity', '1');
        });
      } else {
        group.selectAll('.ellipsis').transition()
          ..delay(100)
          ..attr('opacity', '0');
      }
    } else {
      num textHeight = text.first.clientHeight;
      if (textHeight > axisLength / text.length) {
        text.each((d, i, Element e) {
          if (i > 0 && i < text.length - 1) {
            textOpacity[i] = 0;
          }
          group.selectAll('.ellipsis').transition()
              ..delay(100)
              ..attr('opacity', '1');
        });
      } else {
        group.selectAll('.ellipsis').transition()
            ..delay(100)
            ..attr('opacity', '0');
      }
    }

    text.transition()
      ..attrWithCallback('opacity', (d, i, e) => textOpacity[i])
      ..delay(100);

    // If either the new or old scale is ordinal,
    // entering ticks are undefined in the old scale,
    // and so can fade-in in the new scale’s position.
    // Exiting ticks are likewise undefined in the new scale,
    // and so can fade-out in the old scale’s position.
    var transformFn;
    if (current.rangeBand != 0) {
      var dx = current.rangeBand / 2;
      transformFn = (d) => current.apply(d) + dx;
    } else if (older.rangeBand != 0) {
      older = current;
    } else {
      tickTransform(tickExit, current.apply);
    }

    tickTransform(tickEnter, transformFn != null ? transformFn : older.apply);
    tickTransform(tickUpdate, transformFn != null ?
        transformFn : current.apply);
  }

  _xAxisTransform(selection, transformFn) {
    selection.transition()
      ..attrWithCallback('transform', (d, i, e) =>
        'translate(${transformFn(d)},0)'
    );
  }

  _yAxisTransform(selection, transformFn) {
    selection.transition()
      ..attrWithCallback('transform', (d, i, e) =>
        'translate(0,${transformFn(d)})'
    );
  }
}
