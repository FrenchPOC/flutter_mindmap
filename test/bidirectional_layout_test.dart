import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mindmap/src/layouts/bidirectional_layout.dart';
import 'package:flutter_mindmap/src/models/mindmap_node.dart';
import 'package:flutter_mindmap/src/models/mindmap_edge.dart';

void main() {
  group('BidirectionalLayout', () {
    test('positions root at zero', () {
      final root = MindMapNode(id: 'root', label: 'Root');
      final nodes = [root];
      final edges = <MindMapEdge>[];

      BidirectionalLayout.calculate(nodes, edges, const Size(800, 600));

      expect(root.position, Offset.zero);
    });

    test('distributes children to both sides', () {
      final root = MindMapNode(id: 'root', label: 'Root');
      final child1 = MindMapNode(id: 'c1', label: 'Child 1');
      final child2 = MindMapNode(id: 'c2', label: 'Child 2');

      final nodes = [root, child1, child2];
      final edges = [
        MindMapEdge(fromId: 'root', toId: 'c1'),
        MindMapEdge(fromId: 'root', toId: 'c2'),
      ];

      BidirectionalLayout.calculate(nodes, edges, const Size(800, 600));

      // Root should be at 0,0
      expect(root.position, Offset.zero);

      // One child should be on the right (positive x)
      // One child should be on the left (negative x)
      final rightChild = nodes.firstWhere((n) => n.position.dx > 0);
      final leftChild = nodes.firstWhere((n) => n.position.dx < 0);

      expect(rightChild, isNotNull);
      expect(leftChild, isNotNull);

      // Horizontal spacing check
      expect(rightChild.position.dx, BidirectionalLayout.horizontalSpacing);
      expect(leftChild.position.dx, -BidirectionalLayout.horizontalSpacing);
    });

    test('handles deeper hierarchy', () {
      // root -> c1 (left) -> c1_1
      // root -> c2 (right) -> c2_1
      final root = MindMapNode(id: 'root', label: 'Root');
      final c1 = MindMapNode(id: 'c1', label: 'Left Child');
      final c2 = MindMapNode(id: 'c2', label: 'Right Child');
      final c1_1 = MindMapNode(id: 'c1_1', label: 'Left Grandchild');
      final c2_1 = MindMapNode(id: 'c2_1', label: 'Right Grandchild');

      final nodes = [root, c1, c2, c1_1, c2_1];
      final edges = [
        MindMapEdge(fromId: 'root', toId: 'c1'),
        MindMapEdge(fromId: 'root', toId: 'c2'),
        MindMapEdge(fromId: 'c1', toId: 'c1_1'),
        MindMapEdge(fromId: 'c2', toId: 'c2_1'),
      ];

      BidirectionalLayout.calculate(nodes, edges, const Size(800, 600));

      // Check c1 and c2 are on opposite sides
      expect(c1.position.dx.sign != c2.position.dx.sign, isTrue);

      // Check grandchildren are further out than children
      expect(c1_1.position.dx.abs() > c1.position.dx.abs(), isTrue);
      expect(c2_1.position.dx.abs() > c2.position.dx.abs(), isTrue);

      // Check sides are consistent
      expect(c1_1.position.dx.sign, c1.position.dx.sign);
      expect(c2_1.position.dx.sign, c2.position.dx.sign);
    });
  });
}
