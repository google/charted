/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.demo.treemap;

import 'dart:html';

import '../../lib/layout/layout.dart';
import '../../lib/selection/selection.dart';
import '../../lib/charts/charts.dart';
import 'dart:math';

main() {

  // Label, parent column, value
  var rows = [
    ['aaa', 3, 25],  // p = ddd
    ['bbb', 2, 10],  // p = ccc, leaf
    ['ccc', -1, 145],  // root
    ['ddd', 2, 125],  // p = ccc
    ['eee', 3, 30],  // p = ddd
    ['fff', 4, 10],  // p = eee, leaf
    ['ggg', 3, 30],  // p = ddd, leaf
    ['hhh', 2, 10],  // p = ccc, leaf
    ['iii', 3, 20],  // p = ddd, leaf
    ['jjj', 3, 13],  // p = ddd, leaf
    ['kkk', 3, 7],   // p = ddd, leaf
    ['lll', 4, 15],  // p = eee, leaf
    ['mmm', 4, 5],   // p = eee, leaf
    ['nnn', 0, 13],  // p = aaa, leaf
    ['ooo', 0, 12],  // p = aaa, leaf
    ];

  var width = 400,
      height = 300;

  var theme = new QuantumChartTheme();
  var host = querySelector('.demos-container');
  var scope = new SelectionScope.element(host);
  var root = scope.selectElements([host]);

  void _createTreeMap(var host, var mode) {
    var tree = new TreeMapLayout();
    tree.mode = mode;
    tree.size = [width, height];
    List nodes = tree.layout(rows, 1, 0, 2);
    var treemap = root.select(host);
    var div = treemap.append('div')
      ..style('position', 'relative')
      ..style('width', '${width}px')
      ..style('height', '${height}px');

    var node = div.selectAll(".node").data(nodes);
    node.enter.append("div")
      ..styleWithCallback('left', (d, i, e) => '${d.x}px')
      ..styleWithCallback('top', (d, i, e) => '${d.y}px')
      ..styleWithCallback('width', (d, i, e) => '${max(0, d.dx - 1)}px')
      ..styleWithCallback('height', (d, i, e) => '${max(0, d.dy - 1)}px')
      ..styleWithCallback('background', (d, i, e) => d.children.isNotEmpty ?
          theme.getColorForKey(d.label, ChartTheme.STATE_NORMAL) : null)
      ..textWithCallback((d, i, e) => d.children.isNotEmpty ? null : d.label)
      ..classed('node');

   }
  _createTreeMap('.squarify', TreeMapLayout.TREEMAP_LAYOUT_SQUARIFY);
  _createTreeMap('.slice', TreeMapLayout.TREEMAP_LAYOUT_SLICE);
  _createTreeMap('.dice', TreeMapLayout.TREEMAP_LAYOUT_DICE);
  _createTreeMap('.slicedice', TreeMapLayout.TREEMAP_LAYOUT_SLICE_DICE);
}


