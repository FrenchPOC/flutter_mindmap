import 'package:flutter/material.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';

/// Bidirectional tree layout algorithm
///
/// Arranges nodes in a balanced tree structure with the root in the center,
/// and children distributed to both the left and right sides.
class BidirectionalLayout {
  /// Horizontal spacing between depth levels
  static const double horizontalSpacing = 250.0;

  /// Minimum vertical spacing between sibling nodes
  static const double minVerticalSpacing = 20.0;

  /// Calculates bidirectional layout positions for all nodes
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

    // Split root's children into left and right groups
    final rootChildren = children[root.id] ?? [];
    final leftChildren = <MindMapNode>[];
    final rightChildren = <MindMapNode>[];

    // Simple alternating distribution for balance
    // You could also use heuristics based on subtree size here
    for (var i = 0; i < rootChildren.length; i++) {
      if (i % 2 == 0) {
        rightChildren.add(rootChildren[i]);
      } else {
        leftChildren.add(rootChildren[i]);
      }
    }

    // Position root at (0,0) - the camera will center it
    root.position = Offset.zero;

    // Layout right side
    _layoutSide(
      rightChildren,
      children,
      horizontalSpacing,
      0,
      1, // Direction: 1 for right
    );

    // Layout left side
    _layoutSide(
      leftChildren,
      children,
      -horizontalSpacing,
      0,
      -1, // Direction: -1 for left
    );
  }

  /// Layouts a list of sibling nodes on one side (left or right)
  /// Returns the total height of these siblings
  static double _layoutSide(
    List<MindMapNode> siblings,
    Map<String, List<MindMapNode>> childrenMap,
    double x,
    double startY,
    double direction,
  ) {
    if (siblings.isEmpty) return 0.0;

    // First, calculate the height of each sibling's subtree
    final subtreeHeights = <double>[];
    for (var node in siblings) {
      final nodeChildren = childrenMap[node.id] ?? [];
      final nodeHeight = node.size?.height ?? 60.0;

      if (nodeChildren.isEmpty) {
        subtreeHeights.add(nodeHeight);
      } else {
        // Temporarily calculate children height to know how much space this node needs
        // We'll actually position them in the recursive call below
        final childrenHeight = _calculateSubtreeHeight(node, childrenMap);
        subtreeHeights.add(
          childrenHeight > nodeHeight ? childrenHeight : nodeHeight,
        );
      }
    }

    // Calculate total height of this group of siblings
    final totalHeight =
        subtreeHeights.reduce((a, b) => a + b) +
        minVerticalSpacing * (siblings.length - 1);

    // Start positioning from the top of the block
    var currentY = startY - totalHeight / 2;

    for (var i = 0; i < siblings.length; i++) {
      final node = siblings[i];
      final height = subtreeHeights[i];

      // Position this node vertically centered within its allocated space
      final nodeY = currentY + height / 2;
      node.position = Offset(x, nodeY);

      // Recursively layout children
      final nodeChildren = childrenMap[node.id] ?? [];
      if (nodeChildren.isNotEmpty) {
        _layoutSide(
          nodeChildren,
          childrenMap,
          x + (horizontalSpacing * direction),
          nodeY,
          direction,
        );
      }

      currentY += height + minVerticalSpacing;
    }

    return totalHeight;
  }

  /// Helper to pre-calculate subtree height without positioning
  static double _calculateSubtreeHeight(
    MindMapNode node,
    Map<String, List<MindMapNode>> childrenMap,
  ) {
    final children = childrenMap[node.id] ?? [];
    if (children.isEmpty) {
      return node.size?.height ?? 60.0;
    }

    double totalChildrenHeight = 0;
    for (var child in children) {
      totalChildrenHeight += _calculateSubtreeHeight(child, childrenMap);
    }
    totalChildrenHeight += minVerticalSpacing * (children.length - 1);

    final nodeHeight = node.size?.height ?? 60.0;
    return totalChildrenHeight > nodeHeight ? totalChildrenHeight : nodeHeight;
  }
}
