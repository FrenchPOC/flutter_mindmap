import 'package:flutter/material.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';

/// Hierarchical tree layout algorithm
///
/// Arranges nodes in a tree structure with the root at the top
/// and children distributed evenly below their parents
class TreeLayout {
  /// Calculates tree layout positions for all nodes
  ///
  /// Finds the root node (node with no incoming edges) and recursively
  /// positions children below their parents
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

    // Layout tree starting from root
    _layoutNode(root, children, size.width / 2, 50, size.width, 0);
  }

  /// Recursively positions a node and its children
  ///
  /// Uses a recursive approach to distribute children horizontally
  /// and position them vertically below their parent
  static double _layoutNode(
    MindMapNode node,
    Map<String, List<MindMapNode>> children,
    double x,
    double y,
    double width,
    int depth,
  ) {
    node.position = Offset(x, y);

    final nodeChildren = children[node.id] ?? [];
    if (nodeChildren.isEmpty) return x;

    final childWidth = width / nodeChildren.length;
    double currentX = x - width / 2 + childWidth / 2;

    for (var child in nodeChildren) {
      _layoutNode(
        child,
        children,
        currentX,
        y + 120,
        childWidth * 0.8,
        depth + 1,
      );
      currentX += childWidth;
    }

    return x;
  }
}
