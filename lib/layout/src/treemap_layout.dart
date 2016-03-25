/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.layout;

/// PaddingFunction takes a node and generates the padding for the particular
/// node
typedef List PaddingFunction(TreeMapNode node);

/**
 * Utility layout class which recursively subdivides area into rectangles which
 * can be used to quickly visualize the size of any node in the tree.
 */
class TreeMapLayout extends HierarchyLayout<TreeMapNode> {
  /// Rectangular subdivision; squareness controlled via the target ratio.
  static const TREEMAP_LAYOUT_SQUARIFY = 0;

  /// Horizontal subdivision.
  static const TREEMAP_LAYOUT_SLICE = 1;

  /// Vertical subdivision.
  static const TREEMAP_LAYOUT_DICE = 2;

  /// Alternating between horizontal and vertical subdivision.
  static const TREEMAP_LAYOUT_SLICE_DICE = 3;

  static const _DEFAULT_PADDING = const [0, 0, 0, 0];

  /// A sticky treemap layout will preserve the relative arrangement of nodes
  /// across transitions. (not yet implemented)
  bool _sticky = false;

  /// The available layout size to the specified two-element array of numbers
  /// representing width and height.
  List size = [1, 1];

  /// The mode to layout the Treemap.
  int mode = TREEMAP_LAYOUT_SQUARIFY;

  /// The ration to scale the Treemap.
  num ratio = .5 * (1 + math.sqrt(5));

  /// The paddingFunction for each node, defaults to return [0, 0, 0, 0].
  PaddingFunction paddingFunction = (node) => _DEFAULT_PADDING;

  /// TODO(midoringo): Implement sticky related feature.
  get sticky => _sticky;
  set sticky(bool sticky) {
    _sticky = sticky;
  }

  // TODO (midoringo): handle the sticky case.
  @override
  List<TreeMapNode> layout(
      List rows, int parentColumn, int labelColumn, int valueColumn) {
    var nodes = super.layout(rows, parentColumn, labelColumn, valueColumn);
    var root = nodes[0];
    root.x = 0;
    root.y = 0;
    root.dx = size.first;
    root.dy = size.last;
    _scale([root], root.dx * root.dy / root.value);
    _squarify(root);
    return nodes;
  }

  @override
  TreeMapNode createNode(label, value, depth) {
    return new TreeMapNode()
      ..label = label
      ..value = value
      ..depth = depth;
  }

  void _position(List<TreeMapNode> nodes, num length, MutableRect rect,
      bool flush, num area) {
    var x = rect.x;
    var y = rect.y;
    var v = length > 0 ? (area / length).round() : 0;
    if (length == rect.width) {
      if (flush || (v > rect.height)) v = rect.height;
      for (var node in nodes) {
        node.x = x;
        node.y = y;
        node.dy = v;
        x += node.dx = math.min(
            rect.x + rect.width - x, v > 0 ? (node.area / v).round() : 0);
      }
      nodes.last.sticky = true;
      nodes.last.dx += rect.x + rect.width - x;
      rect.y += v;
      rect.height -= v;
    } else {
      if (flush || (v > rect.width)) v = rect.width;
      for (var node in nodes) {
        node.x = x;
        node.y = y;
        node.dx = v;
        y += node.dy = math.min(
            rect.y + rect.height - y, v > 0 ? (node.area / v).round() : 0);
      }
      nodes.last.sticky = false;
      nodes.last.dy += rect.y + rect.height - y;
      rect.x += v;
      rect.width -= v;
    }
  }

  /// Applies padding between each nodes.
  MutableRect _treeMapPad(TreeMapNode node, padding) {
    var x = node.x + padding[3];
    var y = node.y + padding.first;
    var dx = node.dx - padding[1] - padding[3];
    var dy = node.dy - padding.first - padding[2];
    if (dx < 0) {
      x += dx / 2;
      dx = 0;
    }
    if (dy < 0) {
      y += dy / 2;
      dy = 0;
    }
    return new MutableRect(x, y, dx, dy);
  }

  /// Scales the node base on it's value and the layout area.
  void _scale(List<TreeMapNode> children, var factor) {
    var area;
    for (var child in children) {
      area = child.value * (factor < 0 ? 0 : factor);
      child.area = area <= 0 ? 0 : area;
    }
  }

  /// Computes the most amount of area needed to layout the list of nodes.
  num _worst(List<TreeMapNode> nodes, num length, num pArea) {
    var area;
    var rmax = 0;
    var rmin = double.INFINITY;
    for (var node in nodes) {
      area = node.area;
      if (area <= 0) continue;
      if (area < rmin) rmin = area;
      if (area > rmax) rmax = area;
    }
    pArea *= pArea;
    length *= length;
    return (pArea > 0)
        ? math.max(
            length * rmax * ratio / pArea, pArea / (length * rmin * ratio))
        : double.INFINITY;
  }

  /// Recursively compute each nodes (and its children nodes) position and size
  /// base on the node's property and layout mode.
  void _squarify(TreeMapNode node) {
    var children = node.children;
    if (children.isNotEmpty) {
      var rect = _treeMapPad(node, paddingFunction(node));
      List<TreeMapNode> nodes = [];
      var area = 0;
      var remaining = new List<TreeMapNode>.from(children);
      var score,
          n,
          best = double.INFINITY,
          length = (mode == TREEMAP_LAYOUT_SLICE)
              ? rect.width
              : (mode == TREEMAP_LAYOUT_DICE)
                  ? rect.height
                  : (mode == TREEMAP_LAYOUT_SLICE_DICE)
                      ? (node.depth & 1 == 1) ? rect.height : rect.width
                      : math.min(rect.width, rect.height);
      _scale(remaining, rect.width * rect.height / node.value);
      while ((n = remaining.length) > 0) {
        var child = remaining[n - 1];
        nodes.add(child);
        area += child.area;
        score = _worst(nodes, length, area);
        if (mode != TREEMAP_LAYOUT_SQUARIFY || score <= best) {
          remaining.removeLast();
          best = score;
        } else {
          area -= nodes.removeLast().area;
          _position(nodes, length, rect, false, area);
          length = math.min(rect.width, rect.height);
          nodes.clear();
          area = 0;
          best = double.INFINITY;
        }
      }
      if (nodes.isNotEmpty) {
        _position(nodes, length, rect, true, area);
        nodes.clear();
        area = 0;
      }
      children.forEach(_squarify);
    }
  }
}

class TreeMapNode extends HierarchyNode {
  final List<TreeMapNode> children = <TreeMapNode>[];

  /// The minimum x-coordinate of the node position.
  num x = 0;

  /// The minimum y-coordinate of the node position.
  num y = 0;

  /// The x-extent of the node position.
  num dx = 0;

  /// The y-extent of the node position.
  num dy = 0;

  /// The area the node should take up.
  num area = 0;

  /// Attribute for the last node in the row, only used for sticky layout.
  bool sticky = false;
}
