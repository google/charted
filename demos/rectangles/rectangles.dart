/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demos.rectangles;

import 'package:charted/charted.dart';

void main() {
  SelectionScope scope = new SelectionScope.selector('.wrapper');

  Selection svg = scope.append('svg:svg')
      ..attr('width', 500)
      ..attr('height', 250);

  int offset = 50;
  // When using range domain can be ignored.
  OrdinalScale colorScale = new OrdinalScale();
  colorScale.range = ['#FF0000', '#00FF00', '#0000FF', '#000000'];

  // Opacity of the rectangles, should be 0.8, 0.6, 0.4, 0.2.
  OrdinalScale opacityScale = new OrdinalScale();
  opacityScale.domain = [0, 1, 2, 3];
  opacityScale.rangePoints([0.8, 0.2]);

  OrdinalScale xScale = new OrdinalScale();
  xScale.domain = [0, 1, 2, 3];
  xScale.rangeRoundBands([0, 300], 0.2);

  // Print some scale ticks on the left side.
  LinearScale yScale = new LinearScale();
  yScale.domain = [200, 0];  // same as height
  yScale.rangeRound([0, 1000000]);  // test values.
  List tickValues = yScale.ticks(5);
  FormatFunction f = yScale.tickFormat(5, '\$,');

  DataSelection text = svg.selectAll('.text').data(tickValues);
  text.enter.append('text');
  text..attr('x', 0)
      ..attrWithCallback('y', (d, i, e) => d)
      ..textWithCallback((d, i, e) => f(yScale.apply(d)))
      ..attr('transform', 'translate(0, ${50})')
      ..attr('fill', 'black');
  text.exit.remove();

  // Print some scale ticks on the right side.
  LinearScale pScale = new LinearScale();
  pScale.domain = [200, 0];  // same as height
  pScale.range = [0, 1];  // test values.
  List pTicks = pScale.ticks(10);
  FormatFunction pFormatFunction = pScale.tickFormat(10, '.2%');
  DataSelection text2 = svg.selectAll('.text2').data(pTicks);
  text2.enter.append('text');
  text2..attr('x', 350)
      ..attrWithCallback('y', (d, i, e) => d)
      ..textWithCallback((d, i, e) => pFormatFunction(pScale.apply(d)))
      ..attr('transform', 'translate(0, ${50})')
      ..attr('fill', 'black');
  text2.exit.remove();

  DataSelection rects =
      svg.selectAll('rect').data([40, 120, 160, 80]);
  rects.enter.append('rect');
  rects
      ..attrWithCallback('x', (d,i,e) => xScale.apply(i) + offset)
      ..attrWithCallback('y', (d,i,e) => (250 - d))
      ..attrWithCallback('width', (d,i,e) => xScale.rangeBand)
      ..attrWithCallback('height', (d,i,e) => d)
      ..styleWithCallback('opacity', (d, i, e) =>
          opacityScale.apply(i).toString())
      ..styleWithCallback('fill', (d, i, e) =>
          colorScale.apply(i).toString());
  rects.exit.remove();


  // Bilinear scale parts
  SelectionScope scope2 = new SelectionScope.selector('.wrapper2');

  Selection svg2 = scope2.append('svg:svg')
      ..attr('width', 300)
      ..attr('height', 150);

  LinearScale sizeScale = new LinearScale();
  sizeScale.domain = [0, 3];
  sizeScale.range = [10, 60];

  LinearScale posScale = new LinearScale();
  posScale.domain = [0, 3];
  posScale.range = [0, 240];

  LinearScale linearColorScale = new LinearScale();
  linearColorScale.domain = [0, 3];
  linearColorScale.range = [new Color.fromHex('#FFAA00'),
                            new Color.fromHex('#0066FF')];

  DataSelection rects2 =
     svg2.selectAll('rect2').data([0, 1, 2, 3]);
  rects2.enter.append('rect');
  rects2
      ..attrWithCallback('x', (d,i,e) => posScale.apply(i))
      ..attrWithCallback('y', (d,i,e) => (150 - sizeScale.apply(i)))
      ..attrWithCallback('width', (d,i,e) => sizeScale.apply(i))
      ..attrWithCallback('height', (d,i,e) => sizeScale.apply(i))
      ..styleWithCallback('fill', (d, i, e) =>
          linearColorScale.apply(i).toString());
  rects2.exit.remove();

  // Polylinear scale parts
  SelectionScope scope3 = new SelectionScope.selector('.wrapper3');

  Selection svg3 = scope3.append('svg:svg')
      ..attr('width', 2000)
      ..attr('height', 300);

  // Rectangle size change from 20x20 to 100x100 to 50x50.
  LinearScale polySizeScale = new LinearScale();
  sizeScale.domain = [0, 3, 7];
  sizeScale.range = [20, 100, 50];

  // Position spacing out the rectangle base on size change.
  LinearScale polyPosScale = new LinearScale();
  posScale.domain = [0, 3, 7];
  posScale.range = [0, 300, 800];

  // Changes from red to green to blue.
  LinearScale polylinearColorScale = new LinearScale();
  polylinearColorScale.domain = [0, 3, 7];
  polylinearColorScale.range = [new Color.fromHex('#FF0000'),
                                new Color.fromHex('#00FF00'),
                                new Color.fromHex('#0000FF'),];

  DataSelection rects3 =
     svg3.selectAll('rect3').data([0, 1, 2, 3, 4, 5, 6, 7]);
  rects3.enter.append('rect');
  rects3
      ..attrWithCallback('x', (d,i,e) => posScale.apply(i))
      ..attrWithCallback('y', (d,i,e) => (150 - sizeScale.apply(i)))
      ..attrWithCallback('width', (d,i,e) => sizeScale.apply(i))
      ..attrWithCallback('height', (d,i,e) => sizeScale.apply(i))
      ..styleWithCallback('fill', (d, i, e) =>
          polylinearColorScale.apply(i).toString());
  rects3.exit.remove();
}
