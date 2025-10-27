import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';
import '../layouts/force_directed_layout.dart';
import '../layouts/tree_layout.dart';
import '../painters/mindmap_painter.dart';

/// Main widget for displaying an interactive mind map
///
/// Supports pan and zoom gestures, and can render using either
/// force-directed or tree layout algorithms
class MindMapWidget extends StatefulWidget {
  /// JSON data containing the mind map structure
  ///
  /// Supports two formats:
  /// 1. Object with nodes and edges arrays:
  ///    ```json
  ///    {
  ///      "nodes": [{"id": "1", "label": "Node 1", "color": "#FF6B6B"}],
  ///      "edges": [{"from": "1", "to": "2"}]
  ///    }
  ///    ```
  /// 2. Nested array with children:
  ///    ```json
  ///    [{
  ///      "id": "1",
  ///      "label": "Root",
  ///      "children": [{"id": "2", "label": "Child"}]
  ///    }]
  ///    ```
  final String jsonData;

  /// Whether to use tree layout instead of force-directed layout
  final bool useTreeLayout;

  /// Background color of the canvas
  final Color backgroundColor;

  /// Duration for force-directed animation
  final Duration animationDuration;

  const MindMapWidget({
    Key? key,
    required this.jsonData,
    this.useTreeLayout = false,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.animationDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget>
    with SingleTickerProviderStateMixin {
  List<MindMapNode> nodes = [];
  List<MindMapEdge> edges = [];
  Offset offset = Offset.zero;
  double scale = 1.0;
  Offset? lastFocalPoint;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();

    _parseData();

    animationController.addListener(() {
      if (!widget.useTreeLayout && mounted) {
        setState(() {
          ForceDirectedLayout.calculate(nodes, edges, const Size(800, 600));
        });
      }
    });
  }

  @override
  void didUpdateWidget(MindMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonData != widget.jsonData ||
        oldWidget.useTreeLayout != widget.useTreeLayout) {
      _parseData();
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  /// Parses JSON data and initializes nodes and edges
  void _parseData() {
    try {
      final data = jsonDecode(widget.jsonData);

      nodes.clear();
      edges.clear();

      if (data is Map && data['nodes'] != null) {
        // Format: {nodes: [...], edges: [...]}
        nodes = (data['nodes'] as List)
            .map((n) => MindMapNode.fromJson(n))
            .toList();

        if (data['edges'] != null) {
          edges = (data['edges'] as List)
              .map((e) => MindMapEdge.fromJson(e))
              .toList();
        }
      } else if (data is List) {
        // Format: [{id, label, children: [...]}, ...]
        _parseNestedNodes(data);
      }

      // Apply initial layout
      if (widget.useTreeLayout) {
        TreeLayout.calculate(nodes, edges, const Size(800, 600));
      }
    } catch (e) {
      debugPrint('Error parsing mindmap data: $e');
    }
  }

  /// Recursively parses nested node structure
  void _parseNestedNodes(List<dynamic> data, [String? parentId]) {
    for (var item in data) {
      final node = MindMapNode.fromJson(item);
      nodes.add(node);

      if (parentId != null) {
        edges.add(MindMapEdge(fromId: parentId, toId: node.id));
      }

      if (item['children'] != null && item['children'] is List) {
        _parseNestedNodes(item['children'], node.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        lastFocalPoint = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Handle pan
          if (lastFocalPoint != null) {
            offset += details.focalPoint - lastFocalPoint!;
          }
          lastFocalPoint = details.focalPoint;

          // Handle zoom
          scale = (scale * details.scale).clamp(0.5, 3.0);
        });
      },
      child: Container(
        color: widget.backgroundColor,
        child: CustomPaint(
          painter: MindMapPainter(
            nodes: nodes,
            edges: edges,
            offset: offset,
            scale: scale,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
