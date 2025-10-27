import 'package:flutter/material.dart';

/// Represents a node in the mind map
class MindMapNode {
  /// Unique identifier for the node
  final String id;

  /// Label text displayed on the node
  final String label;

  /// Expansion state explicitly provided by the data source, if any.
  ///
  /// This lets callers override the widget-level defaults for a single node.
  final bool? initialExpanded;

  /// IDs of children nodes
  final List<String> childrenIds;

  /// Current position of the node on the canvas
  Offset position;

  /// Velocity for force-directed layout animation
  Offset velocity;

  /// Background color of the node
  Color color;

  /// Whether the node is expanded (for tree layout)
  bool isExpanded;

  /// Cached size of the rendered node
  Size? size;

  MindMapNode({
    required this.id,
    required this.label,
    this.childrenIds = const [],
    this.initialExpanded,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.color = Colors.blue,
    this.isExpanded = true,
    this.size,
  });

  /// Creates a MindMapNode from JSON data
  ///
  /// Supports both 'label' and 'name' fields for the node label
  /// Color should be provided as hex string (e.g., "#FF6B6B")
  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      childrenIds:
          (json['children'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e['id']?.toString() ?? '')
              .toList() ??
          [],
      color: json['color'] != null
          ? Color(int.parse(json['color'].toString().replaceFirst('#', '0xff')))
          : Colors.blue,
      initialExpanded: json.containsKey('isExpanded')
          ? json['isExpanded'] == true
          : json.containsKey('expanded')
          ? json['expanded'] == true
          : json.containsKey('collapsed')
          ? json['collapsed'] != true
          : null,
      isExpanded: json.containsKey('isExpanded')
          ? json['isExpanded'] == true
          : json.containsKey('expanded')
          ? json['expanded'] == true
          : json.containsKey('collapsed')
          ? json['collapsed'] != true
          : true,
    );
  }

  /// Creates a copy of this node with updated fields
  MindMapNode copyWith({
    String? id,
    String? label,
    List<String>? childrenIds,
    bool? initialExpanded,
    Offset? position,
    Offset? velocity,
    Color? color,
    bool? isExpanded,
    Size? size,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      label: label ?? this.label,
      childrenIds: childrenIds ?? List<String>.from(this.childrenIds),
      initialExpanded: initialExpanded ?? this.initialExpanded,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color ?? this.color,
      isExpanded: isExpanded ?? this.isExpanded,
      size: size ?? this.size,
    );
  }
}
