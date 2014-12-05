/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
library charted.demos.transitions;

import 'package:charted/charted.dart';

void main() {
  SelectionScope scope = new SelectionScope.selector('.wrapper');


  Selection svg = scope.append('svg:svg')
      ..style('width', '4000')
      ..style('height', '4000');


  Selection g1 = svg.append('g');
  g1.attr('transform', 'translate(30, 30)');

  SvgLine line = new SvgLine();

  List lineData = [
      [ [0, 10], [400, 10] ],
      [ [0, 50], [400, 50] ],
      [ [0, 90], [400, 90] ],
      [ [0, 130], [400, 130] ]
  ];
  DataSelection lines = g1.selectAll('.line').data(lineData);

  lines.enter.append('path');
  lines
      ..attrWithCallback('d', (d, i, e) => line.path(d, i, e))
      ..classed('line');
  lines.exit.remove();


  var text1 = g1.append('text');
  text1..attr('x', 0)
       ..attr('y', 0)
       ..text('Transition cubic-in-out');
  var text2 = g1.append('text');
  text2..attr('x', 0)
       ..attr('y', 40)
       ..text('Transition cubic-in');
  var text3 = g1.append('text');
  text3..attr('x', 0)
       ..attr('y', 80)
       ..text('Transition cubic-out');
  var text4 = g1.append('text');
  text4..attr('x', 0)
       ..attr('y', 120)
       ..text('Transition cubic-out-in');

  var circle = g1.append('circle');
  circle
      ..attr('cx', 0)
      ..attr('cy', 10)
      ..attr('r', 4)
      ..classed('circle');

  // Doing transition for first circle with sub transition selection.
  Transition t1 = new Transition(g1);
  t1.duration(4000);
  t1.select('.circle').attr('cx', 400);

  var circle2 = g1.append('circle');
  circle2
      ..attr('cx', 0)
      ..attr('cy', 50)
      ..attr('r', 4);

  Transition t2 = new Transition(circle2);
  t2
      ..ease = clampEasingFn(identityFunction(easeCubic()))
      ..attr('cx', 400)
      ..duration(4000);

  var circle3 = g1.append('circle');
  circle3
      ..attr('cx', 0)
      ..attr('cy', 90)
      ..attr('r', 4);

  Transition t3 = new Transition(circle3);
  t3
      ..ease = clampEasingFn(reverseEasingFn(easeCubic()))
      ..attr('cx', 400)
      ..duration(4000);

  var circle4 = g1.append('circle');
  circle4
      ..attr('cx', 0)
      ..attr('cy', 130)
      ..attr('r', 4);

  Transition t4 = new Transition(circle4);
  t4
      ..ease = clampEasingFn(reflectReverseEasingFn(easeCubic()))
      ..attr('cx', 400)
      ..duration(4000);


  Color dotColor1 = new Color.fromRgb(10, 255, 0);
  Color dotColor2 = new Color.fromRgb(40, 0, 255);
  String shape1 = 'M50 100 L50 200 L100 200 Z';
  String shape2 = 'M900 0 L750 200 L900 200 Z';

  var stringInterpolator = interpolateString(shape1, shape2);

  Selection g2 = svg.append('g');

  var text5 = g2.append('text');
  text5..attr('x', 0)
       ..attr('y', 0)
       ..text('Transition shape and color');

  g2.attr('transform', 'translate(30, 200)');
  g2.attr('width', '1000');
  g2.attr('height', '400');
  Selection shape = g2.append('path');
  shape
      ..attr('d', shape1)
      ..attr('fill', dotColor1);

  Transition t5 = new Transition(shape);
  t5.duration(4000);
  t5.attr('d', shape2);
  t5.attr('fill', dotColor2);

  Selection g3 = svg.append('g');

  var text6 = g3.append('text');
  text6..attr('x', 0)
       ..attr('y', 0)
       ..text('Transition delay');

  g3.attr('transform', 'translate(30, 450)');
  g3.attr('width', '1000');
  g3.attr('height', '1000');

  Selection rect = g3.append('rect');
  rect
      ..attr('x', 0)
      ..attr('y', 10)
      ..attr('width', 40)
      ..attr('height', 40)
      ..attr('fill', '#FF0000');

  Transition t6 = new Transition(rect);
  t6.duration(4000);
  t6.delay(4000);
  t6.attr('x', 400);
  t6.attr('fill', '#00FF00');

  var t7 = t6.transition();
  t7.attr('y', 400);
  t7.attr('fill', '#0000FF');

  var t8 = t7.transition();
  t8.attr('x', 0);
  t8.attr('fill', '#FF00FF');

  var t9 = t8.transition();
  t9.attr('y', 10);
  t9.attr('fill', '#FF0000');

  Selection g4 = svg.append('g');
  DataSelection bars =
      g4.selectAll('bar').data([120, 160, 210, 260]);
  g4.attr('transform', 'translate(30, 850)');
  bars.enter.append('rect');
  bars
      ..attrWithCallback('x', (d,i,e) => i * 150)
      ..attr('y', 350)
      ..attr('width', 100)
      ..attr('height', 0)
      ..style('fill', '#6699FF');
  bars.exit.remove();

  var t = bars.transition();
  t.duration(1000);
  t.delayWithCallback((d, i, c) => i * 200);
  t.attrTween('y', (d, i, attr) => interpolateString(
      attr, (350 - d).toString()));
  t.attrTween('height', (d, i, attr) => interpolateString(attr, d.toString()));

  var color = t.transition();
  color.delayWithCallback((d, i, c) => i * 200);
  color.styleTween('fill',
      (d, i, style) => interpolateString(style, '#CC0088'));

  Color hslColor1 = new Color.fromRgb(10, 255, 0);
  Color hslColor2 = new Color.fromRgb(40, 0, 255);
  Selection g5 = svg.append('g');
  var text7 = g5.append('text');
  text7..attr('x', 0)
       ..attr('y', 0)
       ..text('HSL Color Transition with Transform');

  g5.attr('transform', 'translate(30, 1300)');

  Selection rect2 = g5.append('rect');
  rect2
      ..attr('x', 0)
      ..attr('y', 10)
      ..attr('width', 200)
      ..attr('height', 60);
  rect2.transition()
      ..attrTween('fill', (d, i, e) {
        return interpolateHsl(hslColor1, hslColor2);})
      ..duration(2000);

  rect2.transition()
      ..attrTween('transform', (d, i, e) => interpolateTransform(
          "translate(10,10)rotate(30)skewX(0.5)scale(1,1)",
          "translate(100,100)rotate(360)skewX(45)scale(3,3)"))
      ..duration(5000);

}

