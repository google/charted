/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.layout;

typedef int SortFunction(HierarchyNode a, HierarchyNode b);
typedef List ChildrenAccessor(HierarchyNode node);
typedef num ValueAccessor(HierarchyNode node);

/**
 * The hierarchy layout is an abstract layout that is not used directly, but
 * instead allows code sharing between multiple hierarchical layouts such as:
 * Cluster, Pack, Partition, Tree, and Treemap layout.
 */
abstract class HierarchyLayout<T extends HierarchyNode> {
  static const ROOT_ROW_INDEX = -1;
  SortFunction sortFunction = hierarchySort;
  ChildrenAccessor childrenAccessor = hierarchyChildren;
  ValueAccessor valueAccessor = hierarchyValue;

  /// Returns the list of HierarchyNode constructed from the given data and
  /// parentColumn and valueColumn which is used to construct the hierarchy.
  /// The returned list of nodes contains the hierarchy with root being the
  /// first element its children in depth first order.
  List<T> layout(
      List rows, int parentColumn, int labelColumn, int valueColumn) {
    List<T> nodeList = [];
    for (var row in rows) {
      nodeList.add(createNode(row[labelColumn], row[valueColumn], 0));
    }

    for (var i = 0; i < rows.length; i++) {
      int parentRow = rows[i][parentColumn];
      if (parentRow == ROOT_ROW_INDEX) continue;
      var currentNode = nodeList[i];
      var parentNode = nodeList[parentRow];
      parentNode.children.add(currentNode);
      currentNode.parent = parentNode;
      currentNode.depth = parentNode.depth + 1;
      for (var child in currentNode.children) {
        child.depth += 1;
      }
    }

    // Reorder the list so that root is the first element and the list contains
    // the hierarchy of nodes in depth first order.
    var hierarchyNodeList = <HierarchyNode>[];
    var root = nodeList.where((e) => e.depth == 0).elementAt(0);
    var children = <HierarchyNode>[root];
    while (children.length > 0) {
      var node = children.removeLast();
      children.addAll(node.children);
      hierarchyNodeList.add(node);
    }

    return hierarchyNodeList;
  }

  T createNode(label, value, depth);

  /// Default accessor method for getting the list of children of the node.
  static List hierarchyChildren(HierarchyNode node) => node.children;

  /// Default accessor method for getting the value of the node.
  static num hierarchyValue(HierarchyNode node) => node.value;

  /// Default sorting method for comparing node a and b.
  static int hierarchySort(HierarchyNode a, HierarchyNode b) =>
      b.value - a.value;
}

abstract class HierarchyNode {
  /// The parent node, or null for the root.
  HierarchyNode parent = null;

  /// The list of children nodes, or null for leaf nodes.
  List<HierarchyNode> get children;

  /// The label to show for each block of hierarchy
  String label = '';

  /// The node value, as returned by the value accessor.
  dynamic value;

  /// The depth of the node, starting at 0 for the root.
  int depth = 0;
}
