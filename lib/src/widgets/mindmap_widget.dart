import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /// Whether rendered cards are allowed to overlap after layout
  ///
  /// When set to `false`, a lightweight collision resolution pass keeps
  /// nodes separated while preserving the overall layout shape.
  final bool allowNodeOverlap;

  /// Whether nodes should be expanded by default when the widget loads.
  ///
  /// Can be overridden per-node via JSON (`isExpanded`, `expanded`, or `collapsed`)
  /// or by providing `initiallyExpandedNodeIds` / `initiallyCollapsedNodeIds`.
  final bool expandAllNodesByDefault;

  /// Explicit list of node IDs that should start expanded.
  ///
  /// Useful when setting [expandAllNodesByDefault] to `false` but leaving a few
  /// branches open initially.
  final Set<String>? initiallyExpandedNodeIds;

  /// Explicit list of node IDs that should start collapsed.
  final Set<String>? initiallyCollapsedNodeIds;

  /// Duration for force-directed animation
  final Duration animationDuration;

  const MindMapWidget({
    super.key,
    required this.jsonData,
    this.useTreeLayout = false,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.allowNodeOverlap = true,
    this.expandAllNodesByDefault = true,
    this.initiallyExpandedNodeIds,
    this.initiallyCollapsedNodeIds,
    this.animationDuration = const Duration(seconds: 2),
  });

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget>
    with SingleTickerProviderStateMixin {
  List<MindMapNode> _allNodes = [];
  List<MindMapEdge> _allEdges = [];
  List<MindMapNode> _visibleNodes = [];
  List<MindMapEdge> _visibleEdges = [];
  Map<String, MindMapNode> _nodeLookup = {};
  Map<String, List<String>> _childrenMap = {};
  List<String> _rootIds = [];
  Offset offset = Offset.zero;
  double scale = 1.0;
  Offset? lastFocalPoint;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: widget.animationDuration)
          ..addListener(() {
            if (!widget.useTreeLayout && mounted && _visibleNodes.isNotEmpty) {
              setState(() {
                ForceDirectedLayout.calculate(
                  _visibleNodes,
                  _visibleEdges,
                  const Size(800, 600),
                );
                if (!widget.allowNodeOverlap) {
                  _resolveOverlaps();
                }
              });
            }
          });

    if (!widget.useTreeLayout) {
      animationController.repeat();
    }

    _parseData();
  }

  @override
  void didUpdateWidget(MindMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationDuration != widget.animationDuration) {
      animationController.duration = widget.animationDuration;
      if (!widget.useTreeLayout && !animationController.isAnimating) {
        animationController.repeat();
      }
    }

    if (oldWidget.useTreeLayout != widget.useTreeLayout) {
      if (widget.useTreeLayout) {
        animationController.stop();
      } else {
        animationController.repeat();
      }
    }

    final shouldReparse =
        oldWidget.jsonData != widget.jsonData ||
        oldWidget.useTreeLayout != widget.useTreeLayout ||
        oldWidget.expandAllNodesByDefault != widget.expandAllNodesByDefault ||
        !_setsEqual(
          oldWidget.initiallyExpandedNodeIds,
          widget.initiallyExpandedNodeIds,
        ) ||
        !_setsEqual(
          oldWidget.initiallyCollapsedNodeIds,
          widget.initiallyCollapsedNodeIds,
        ) ||
        oldWidget.allowNodeOverlap != widget.allowNodeOverlap;

    if (shouldReparse) {
      _parseData();
      return;
    }

    if (oldWidget.allowNodeOverlap != widget.allowNodeOverlap) {
      setState(_runLayout);
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
      final parsedNodes = <MindMapNode>[];
      final parsedEdges = <MindMapEdge>[];

      if (data is Map && data['nodes'] != null) {
        // Format: {nodes: [...], edges: [...]}
        parsedNodes.addAll(
          (data['nodes'] as List).map((n) => MindMapNode.fromJson(n)).toList(),
        );

        if (data['edges'] != null) {
          parsedEdges.addAll(
            (data['edges'] as List)
                .map((e) => MindMapEdge.fromJson(e))
                .toList(),
          );
        }
      } else if (data is List) {
        // Format: [{id, label, children: [...]}, ...]
        _parseNestedNodes(data, parsedNodes, parsedEdges);
      }

      _allNodes = parsedNodes;
      _allEdges = parsedEdges;

      _buildGraphStructure();
      _applyDefaultExpansion();
      _rebuildVisibility();
      _runLayout();

      setState(() {});
    } catch (e) {
      debugPrint('Error parsing mindmap data: $e');
    }
  }

  /// Recursively parses nested node structure
  void _parseNestedNodes(
    List<dynamic> data,
    List<MindMapNode> nodeList,
    List<MindMapEdge> edgeList, [
    String? parentId,
  ]) {
    for (var item in data) {
      final node = MindMapNode.fromJson(item);
      nodeList.add(node);

      if (parentId != null) {
        edgeList.add(MindMapEdge(fromId: parentId, toId: node.id));
      }

      if (item['children'] != null && item['children'] is List) {
        _parseNestedNodes(item['children'], nodeList, edgeList, node.id);
      }
    }
  }

  void _buildGraphStructure() {
    _nodeLookup = {for (var node in _allNodes) node.id: node};

    _childrenMap = {};
    final incoming = <String>{};

    for (var edge in _allEdges) {
      final children = _childrenMap.putIfAbsent(edge.fromId, () => <String>[]);
      if (!children.contains(edge.toId)) {
        children.add(edge.toId);
      }
      incoming.add(edge.toId);
    }

    _rootIds = _allNodes
        .where((node) => !incoming.contains(node.id))
        .map((node) => node.id)
        .toList();

    if (_rootIds.isEmpty && _allNodes.isNotEmpty) {
      _rootIds = [_allNodes.first.id];
    }
  }

  void _applyDefaultExpansion() {
    for (var node in _allNodes) {
      node.isExpanded = widget.expandAllNodesByDefault;
      if (node.initialExpanded != null) {
        node.isExpanded = node.initialExpanded!;
      }
    }

    if (widget.initiallyExpandedNodeIds != null) {
      for (var node in _allNodes) {
        if (widget.initiallyExpandedNodeIds!.contains(node.id)) {
          node.isExpanded = true;
        }
      }
    }

    if (widget.initiallyCollapsedNodeIds != null) {
      for (var node in _allNodes) {
        if (widget.initiallyCollapsedNodeIds!.contains(node.id)) {
          node.isExpanded = false;
        }
      }
    }
  }

  void _rebuildVisibility() {
    final visibleIds = <String>{};
    final queue = <String>[];

    if (_rootIds.isEmpty && _allNodes.isNotEmpty) {
      queue.add(_allNodes.first.id);
    } else {
      queue.addAll(_rootIds);
    }

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      if (!visibleIds.add(currentId)) continue;

      final node = _nodeLookup[currentId];
      if (node == null) continue;

      if (node.isExpanded) {
        queue.addAll(_childrenMap[currentId] ?? const <String>[]);
      }
    }

    _visibleNodes = [
      for (var id in visibleIds)
        if (_nodeLookup[id] != null) _nodeLookup[id]!,
    ];
    _visibleEdges = _allEdges
        .where(
          (edge) =>
              visibleIds.contains(edge.fromId) &&
              visibleIds.contains(edge.toId),
        )
        .toList();
  }

  void _runLayout() {
    if (_visibleNodes.isEmpty) return;

    if (widget.useTreeLayout) {
      TreeLayout.calculate(_visibleNodes, _visibleEdges, const Size(800, 600));
    } else {
      ForceDirectedLayout.calculate(
        _visibleNodes,
        _visibleEdges,
        const Size(800, 600),
      );
    }

    if (!widget.allowNodeOverlap) {
      _resolveOverlaps();
    }
  }

  void _ensureNodeSizes() {
    for (final node in _visibleNodes) {
      node.size ??= _measureNodeSize(node);
    }
  }

  Size _measureNodeSize(MindMapNode node) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(
      maxWidth: MindMapPainter.maxWidth - MindMapPainter.padding * 2,
    );

    final width = math.min(
      textPainter.width + MindMapPainter.padding * 2,
      MindMapPainter.maxWidth,
    );

    final size = Size(
      width,
      textPainter.height + MindMapPainter.padding * 2,
    );

    return size;
  }

  void _resolveOverlaps() {
    if (_visibleNodes.length < 2) {
      return;
    }

    _ensureNodeSizes();

    const double separationPadding = 12.0;
    const int maxIterations = 10;

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      var overlapFound = false;

      for (var i = 0; i < _visibleNodes.length; i++) {
        final nodeA = _visibleNodes[i];
        final sizeA = nodeA.size ?? const Size(100, 60);

        for (var j = i + 1; j < _visibleNodes.length; j++) {
          final nodeB = _visibleNodes[j];
          final sizeB = nodeB.size ?? const Size(100, 60);

          final dx = nodeA.position.dx - nodeB.position.dx;
          final dy = nodeA.position.dy - nodeB.position.dy;

          final overlapX =
              (sizeA.width + sizeB.width) / 2 + separationPadding - dx.abs();
          final overlapY =
              (sizeA.height + sizeB.height) / 2 + separationPadding - dy.abs();

          if (overlapX <= 0 || overlapY <= 0) {
            continue;
          }

          overlapFound = true;

          if (overlapX < overlapY) {
            final direction = dx == 0
                ? (i.isEven ? 1.0 : -1.0)
                : dx.sign;
            final shift = overlapX / 2 * direction;
            nodeA.position = nodeA.position.translate(shift, 0);
            nodeB.position = nodeB.position.translate(-shift, 0);
          } else {
            final direction = dy == 0
                ? (i.isEven ? 1.0 : -1.0)
                : dy.sign;
            final shift = overlapY / 2 * direction;
            nodeA.position = nodeA.position.translate(0, shift);
            nodeB.position = nodeB.position.translate(0, -shift);
          }
        }
      }

      if (!overlapFound) {
        break;
      }
    }
  }

  void _handleTap(Offset localPosition) {
    final transformed = (localPosition - offset) / (scale == 0 ? 1.0 : scale);

    for (final node in _visibleNodes.reversed) {
      final nodeSize = node.size ?? const Size(100, 60);
      final rect = Rect.fromCenter(
        center: node.position,
        width: nodeSize.width,
        height: nodeSize.height,
      );

      if (rect.contains(transformed)) {
        final hasChildren = (_childrenMap[node.id]?.isNotEmpty ?? false);
        if (!hasChildren) {
          return;
        }

        setState(() {
          node.isExpanded = !node.isExpanded;
          _rebuildVisibility();
          _runLayout();
        });
        return;
      }
    }
  }

  bool _setsEqual(Set<String>? a, Set<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    return setEquals(a, b);
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
      onScaleEnd: (details) {
        lastFocalPoint = null;
      },
      onTapUp: (details) {
        _handleTap(details.localPosition);
      },
      child: Container(
        color: widget.backgroundColor,
        child: CustomPaint(
          painter: MindMapPainter(
            nodes: _visibleNodes,
            edges: _visibleEdges,
            offset: offset,
            scale: scale,
            childrenMap: _childrenMap,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
