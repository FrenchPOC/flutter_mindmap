import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';

void main() {
  group('MindMapNode', () {
    test('should create node from JSON with explicit nodes format', () {
      final json = {'id': '1', 'label': 'Test Node', 'color': '#FF6B6B'};

      final node = MindMapNode.fromJson(json);

      expect(node.id, equals('1'));
      expect(node.label, equals('Test Node'));
      expect(node.color.value, equals(0xFFFF6B6B));
    });

    test('should handle name field as label', () {
      final json = {'id': '2', 'name': 'Test Name'};

      final node = MindMapNode.fromJson(json);

      expect(node.id, equals('2'));
      expect(node.label, equals('Test Name'));
    });
  });

  group('MindMapEdge', () {
    test('should create edge from JSON', () {
      final json = {'from': '1', 'to': '2'};

      final edge = MindMapEdge.fromJson(json);

      expect(edge.fromId, equals('1'));
      expect(edge.toId, equals('2'));
    });

    test('should convert edge to JSON', () {
      final edge = const MindMapEdge(fromId: '1', toId: '2');
      final json = edge.toJson();

      expect(json['from'], equals('1'));
      expect(json['to'], equals('2'));
    });

    test('should check equality correctly', () {
      const edge1 = MindMapEdge(fromId: '1', toId: '2');
      const edge2 = MindMapEdge(fromId: '1', toId: '2');
      const edge3 = MindMapEdge(fromId: '2', toId: '3');

      expect(edge1, equals(edge2));
      expect(edge1, isNot(equals(edge3)));
    });
  });
}
