/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demos.lines;

import 'dart:math';
import 'package:charted/charted.dart';

void main() {
  // Draw lines.
  SelectionScope scope = new SelectionScope.selector('.wrapper');

  Selection svg = scope.append('svg:svg')
      ..attr('width', 50)
      ..attr('height', 50);

  SvgLine line = new SvgLine();

  List data = [
        [ [10, 10], [20, 20], [30, 30], [40, 40] ],
        [ [15, 10], [25, 20], [35, 30], [45, 40] ]
      ];
  DataSelection lines = svg.selectAll('.line').data(data);

  lines.enter.append('path');
  lines
      ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
      ..classed('line');
  lines.exit.remove();


  // Draw line by interpolation.
  SelectionScope scope2 = new SelectionScope.selector('.wrapper2');

  Selection svg2 = scope2.append('svg:svg')
      ..attr('width', 1000)
      ..attr('height', 300);

  SvgLine line2 = new SvgLine();
  Point p1 = new Point(20, 20);
  Point p2 = new Point(203, 256);
  Color dotColor1 = new Color.fromRgb(10, 255, 0);
  Color dotColor2 = new Color.fromRgb(40, 0, 255);
  List tweens = [0, 0.2, 0.3, 0.5, 0.75, 1];

  var xInterpolator = interpolator(p1.x, p2.x);
  var yInterpolator = interpolator(p1.y, p2.y);
  var colorInterpolator = interpolator(dotColor1, dotColor2);

  List<Point> points = new List.generate(tweens.length, (i) => new Point(
      xInterpolator(tweens[i]), yInterpolator(tweens[i])));
  List<List> coords = new List.generate(tweens.length, (i) => [
      xInterpolator(tweens[i]), yInterpolator(tweens[i])]);
  List lineData = [coords];
  DataSelection redLines = svg2.selectAll('.red-line').data(lineData);
  redLines.enter.append('path');
  redLines
      ..attrWithCallback('d', (d, i, e) => line2.path(d, i, e))
      ..classed('red-line');
  redLines.exit.remove();

  DataSelection dots = svg2.selectAll('.dots').data(points);
  dots.enter.append('circle');
  dots..attrWithCallback('cx', (d, i, e) => d.x)
      ..attrWithCallback('cy', (d, i, e) => d.y)
      ..attr('r', 3)
      ..attrWithCallback('stroke', (d, i, e) => colorInterpolator(tweens[i]))
      ..attrWithCallback('fill', (d, i, e) => colorInterpolator(tweens[i]));
  dots.exit.remove();

  DataSelection text = svg2.selectAll('.text').data(points);
  text.enter.append('text');
  text..attrWithCallback('x', (d, i, e) => d.x)
      ..attrWithCallback('y', (d, i, e) => d.y)
      ..textWithCallback((d, i, e) =>
          't = ${tweens[i]}, coord = (${d.x}, ${d.y}), color = '
          '${colorInterpolator(tweens[i]).rgbString}')
      ..attr('transform', 'translate(20, 0)')
      ..attr('fill', 'black');
  text.exit.remove();


  // Draw shape by interpolation.
  SelectionScope scope3 = new SelectionScope.selector('.wrapper3');
  String shape1 = 'M50 100 L50 200 L100 200 Z';
  String shape2 = 'M900 0 L750 200 L900 200 Z';

  var stringInterpolator = interpolator(shape1, shape2);
  Selection svg3 = scope3.append('svg:svg')
      ..attr('width', 1000)
      ..attr('height', 300);

  DataSelection shapes = svg3.selectAll('.shapes').data(new List.generate(
      tweens.length, (i) => stringInterpolator(tweens[i])));
  shapes.enter.append('path');
  shapes
      ..attrWithCallback('d', (d, i, e) => d)
      ..attrWithCallback('fill', (d, i, e) =>
          colorInterpolator(tweens[i]).hexString);
  shapes.exit.remove();

  var numInterpolator = interpolateNumber(50, 750);
  DataSelection text2 = svg3.selectAll('.text2').data(new List.generate(
      tweens.length, (i) => numInterpolator(tweens[i])));
    text2.enter.append('text');
    text2..attrWithCallback('x', (d, i, e) => d)
        ..attr('y', 200)
        ..textWithCallback((d, i, e) =>
            't = ${tweens[i]}')
        ..attr('transform', 'translate(0, 14)')
        ..attr('fill', 'black');
    text2.exit.remove();

    SelectionScope scope4 = new SelectionScope.selector('.wrapper4');
    Selection svg4 = scope4.append('svg:svg')
        ..attr('width', 1000)
        ..attr('height', 400);
    var g = svg4.append('g');
    g.attr('transform', 'translate(50, 50)');

    LinearScale x = new LinearScale();
       x.domain = [1, 10];
       x.range =  [0, 600];

       LinearScale y = new LinearScale();
       y.domain = [0, 300];
       y.range = [300, 0];

       var scale = new LogScale();
       scale.range = [300, 0];


       var logLine = new SvgLine();
       logLine.xAccessor = (d, i) => x.apply(d);
       logLine.yAccessor = (d, i) => scale.apply(d);

       var product = g.selectAll(".lines").data(
           [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]]);
       product.enter.append("path").attr("class", "lines");
       product
           ..attr('class', 'line')
           ..attrWithCallback('d', (d, i, e) => logLine.path(d, i, e))
           ..style('stroke', 'blue')
           ..style('fill', 'none');

       SvgAxis xAxis = new SvgAxis();
       xAxis.scale = x;
       xAxis.orientation = SvgAxis.ORIENTATION_BOTTOM;

       SvgAxis yAxis = new SvgAxis();
       yAxis.scale = y;
       yAxis.orientation = SvgAxis.ORIENTATION_LEFT;

       xAxis.axis(g.append('g')
           ..attr('class', 'x-axis')
           ..attr('transform', 'translate(0, 300)'));

       yAxis.axis(g.append('g')
           ..attr('class', 'y-axis'));
}

