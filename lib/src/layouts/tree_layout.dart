import 'package:flutter/material.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';

/// Hierarchical tree layout algorithm
///
/// Arranges nodes in a horizontal tree structure with the root on the left
/// and children expanding to the right, similar to Google Notebook mind maps
class TreeLayout {
  /// Horizontal spacing between depth levels
  static const double horizontalSpacing = 350.0;

  /// Minimum vertical spacing between sibling nodes
  static const double minVerticalSpacing = 20.0;

  /// Left margin from canvas edge
  static const double leftMargin = 100.0;

  /// Calculates tree layout positions for all nodes
  ///
  /// Finds the root node (node with no incoming edges) and recursively
  /// positions children to the right of their parents
  static void calculate(
    List<MindMapNode> nodes,
    List<MindMapEdge> edges,
    Size size,
  ) {
    if (nodes.isEmpty) return;

    // Find root (node with no incoming edges)
    final hasIncoming = edges.map((e) => e.toId).toSet();
    final root = nodes.firstWhere(
      (n) => !hasIncoming.contains(n.id),
      orElse: () => nodes.first,
    );

    // Build tree structure
    final Map<String, List<MindMapNode>> children = {};
    for (var edge in edges) {
      children.putIfAbsent(edge.fromId, () => []);
      final child = nodes.firstWhere((n) => n.id == edge.toId);
      children[edge.fromId]!.add(child);
    }

    // Layout tree starting from root (horizontal orientation)
    // Start at y=0, we'll center the whole tree afterward
    _layoutNode(root, children, leftMargin, 0.0, 0);
  }

  /// Recursively positions a node and its children horizontally
  ///
  /// Returns the height of the subtree rooted at this node
  static double _layoutNode(
    MindMapNode node,
    Map<String, List<MindMapNode>> children,
    double x,
    double y,
    int depth,
  ) {
    final nodeChildren = children[node.id] ?? [];
    final nodeHeight = node.size?.height ?? 60.0;

    if (nodeChildren.isEmpty) {
      // Leaf node
      node.position = Offset(x, y + nodeHeight / 2);
      return nodeHeight;
    }

    // Layout children first to determine their positions and total height
    final childX = x + horizontalSpacing;
    double currentY = y;
    final childHeights = <double>[];

    for (var child in nodeChildren) {
      final childHeight = _layoutNode(
        child,
        children,
        childX,
        currentY,
        depth + 1,
      );
      childHeights.add(childHeight);
      currentY += childHeight + minVerticalSpacing;
    }

    // Calculate total height of all children including spacing
    final totalChildrenHeight =
        childHeights.reduce((a, b) => a + b) +
        minVerticalSpacing * (nodeChildren.length - 1);

    // Position parent at the vertical center of its children's total height
    final parentY = y + totalChildrenHeight / 2;
    node.position = Offset(x, parentY);

    // Return the maximum height: either the parent's height or children's total height
    return totalChildrenHeight > nodeHeight ? totalChildrenHeight : nodeHeight;
  }
}
