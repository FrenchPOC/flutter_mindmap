import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
    with TickerProviderStateMixin {
  List<MindMapNode> _allNodes = [];
  List<MindMapEdge> _allEdges = [];
  List<MindMapNode> _visibleNodes = [];
  List<MindMapEdge> _visibleEdges = [];
  Map<String, MindMapNode> _nodeLookup = {};
  Map<String, List<String>> _childrenMap = {};
  List<String> _rootIds = [];
  Set<String> _newlyAnimatedNodeIds =
      {}; // Track nodes that just became visible
  Set<String> _newlyAnimatedEdgeIds =
      {}; // Track edges connecting to newly animated nodes
  Offset offset = Offset.zero;
  double scale = 1.0;
  Offset? lastFocalPoint;
  late AnimationController animationController;
  late AnimationController expansionController;
  late AnimationController cameraController; // For smooth camera transitions
  Offset _targetOffset = Offset.zero; // Target camera offset
  Size _canvasSize = const Size(800, 600);
  bool _autoCenterPending = true;
  bool _hasUserPannedOrZoomed = false;
  bool _sizeUpdateScheduled = false;
  double _expansionProgress = 1.0;
  double _edgeOpacity = 1.0; // Track edge fade-in animation
  bool _isExpanding =
      true; // Track if we're expanding (true) or collapsing (false)

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
                  _canvasSize,
                );
                if (!widget.allowNodeOverlap) {
                  _resolveOverlaps();
                }
              });
            }
          });

    // Expansion/collapse animation controller
    expansionController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          )
          ..addListener(() {
            if (mounted) {
              setState(() {
                _expansionProgress = expansionController.value;

                if (_isExpanding) {
                  // During EXPAND: edges fade in after nodes are 70% animated
                  const double fadeStartProgress = 0.7;
                  if (_expansionProgress < fadeStartProgress) {
                    _edgeOpacity = 0.0;
                  } else {
                    // Fade in: 0.0 → 1.0 over remaining 30% of animation
                    final fadeFactor =
                        (_expansionProgress - fadeStartProgress) /
                        (1.0 - fadeStartProgress);
                    _edgeOpacity = fadeFactor;
                  }
                } else {
                  // During COLLAPSE: edges fade out faster, starting at 30%
                  const double fadeStartProgress = 0.3;
                  if (_expansionProgress < fadeStartProgress) {
                    _edgeOpacity = 1.0;
                  } else {
                    // Fade out: 1.0 → 0.0 over remaining 70% of animation
                    final fadeFactor =
                        (_expansionProgress - fadeStartProgress) /
                        (1.0 - fadeStartProgress);
                    _edgeOpacity = 1.0 - fadeFactor;
                  }
                }
              });
            }
          })
          ..addStatusListener((status) {
            // After collapse animation completes, remove disappearing nodes
            if (status == AnimationStatus.completed && !_isExpanding) {
              if (mounted) {
                setState(() {
                  _rebuildVisibility();
                });
              }
            }
          });

    // Camera animation controller for smooth viewport transitions
    cameraController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        )..addListener(() {
          if (mounted) {
            setState(() {
              // Smoothly interpolate offset during camera animation
              offset =
                  Offset.lerp(offset, _targetOffset, cameraController.value) ??
                  offset;
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
        );

    if (shouldReparse) {
      _autoCenterPending = true;
      _parseData();
      return;
    }

    if (oldWidget.allowNodeOverlap != widget.allowNodeOverlap) {
      if (!_hasUserPannedOrZoomed) {
        _autoCenterPending = true;
      }
      setState(_runLayout);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    expansionController.dispose();
    cameraController.dispose();
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

      offset = Offset.zero;
      scale = 1.0;
      _hasUserPannedOrZoomed = false;
      _autoCenterPending = true;

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
      TreeLayout.calculate(_visibleNodes, _visibleEdges, _canvasSize);
    } else {
      ForceDirectedLayout.calculate(_visibleNodes, _visibleEdges, _canvasSize);
    }

    if (!widget.allowNodeOverlap) {
      _resolveOverlaps();
    }

    _ensureNodeSizes();
    _applyAutoCenterIfNeeded();
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
        style: TextStyle(
          color: Colors.grey.shade900,
          fontSize: 14,
          fontWeight: FontWeight.w600,
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

    final size = Size(width, textPainter.height + MindMapPainter.padding * 2);

    return size;
  }

  void _resolveOverlaps() {
    if (_visibleNodes.length < 2) {
      return;
    }

    _ensureNodeSizes();

    const double separationPadding = 12.0;
    const int maxIterations = 10;
    final originalCenter = _computeCentroid(_visibleNodes);
    var anyOverlap = false;

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
          final tieBreakDirection = ((i + j).isEven ? -1.0 : 1.0);

          final overlapX =
              (sizeA.width + sizeB.width) / 2 + separationPadding - dx.abs();
          final overlapY =
              (sizeA.height + sizeB.height) / 2 + separationPadding - dy.abs();

          if (overlapX <= 0 || overlapY <= 0) {
            continue;
          }

          overlapFound = true;

          if (overlapX < overlapY) {
            final direction = dx == 0 ? tieBreakDirection : dx.sign;
            final shift = overlapX / 2 * direction;
            nodeA.position = nodeA.position.translate(shift, 0);
            nodeB.position = nodeB.position.translate(-shift, 0);
          } else {
            final direction = dy == 0 ? tieBreakDirection : dy.sign;
            final shift = overlapY / 2 * direction;
            nodeA.position = nodeA.position.translate(0, shift);
            nodeB.position = nodeB.position.translate(0, -shift);
          }
        }
      }

      if (!overlapFound) {
        break;
      }

      anyOverlap = true;
    }

    if (!anyOverlap) {
      return;
    }

    final adjustedCenter = _computeCentroid(_visibleNodes);
    final delta = adjustedCenter - originalCenter;

    if (delta != Offset.zero) {
      for (final node in _visibleNodes) {
        node.position -= delta;
      }
    }

    for (final node in _visibleNodes) {
      node.velocity = Offset.zero;
    }
  }

  void _applyAutoCenterIfNeeded() {
    if (!_autoCenterPending) {
      return;
    }

    if (_canvasSize == Size.zero) {
      return;
    }

    final bounds = _computeBounds(_visibleNodes);
    if (bounds == null) {
      return;
    }

    final contentCenter = bounds.center;
    final viewCenter = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

    // Calculate the new offset to center the content
    _targetOffset = viewCenter - contentCenter;

    // Animate camera to the target offset smoothly
    cameraController.forward(from: 0.0);

    _autoCenterPending = false;
  }

  Offset _computeCentroid(List<MindMapNode> nodes) {
    if (nodes.isEmpty) {
      return Offset.zero;
    }

    var sumX = 0.0;
    var sumY = 0.0;

    for (final node in nodes) {
      sumX += node.position.dx;
      sumY += node.position.dy;
    }

    final count = nodes.length.toDouble();
    return Offset(sumX / count, sumY / count);
  }

  Rect? _computeBounds(List<MindMapNode> nodes) {
    if (nodes.isEmpty) {
      return null;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      final size = node.size ?? const Size(100, 60);
      final left = node.position.dx - size.width / 2;
      final right = node.position.dx + size.width / 2;
      final top = node.position.dy - size.height / 2;
      final bottom = node.position.dy + size.height / 2;

      if (left < minX) minX = left;
      if (right > maxX) maxX = right;
      if (top < minY) minY = top;
      if (bottom > maxY) maxY = bottom;
    }

    if (!minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite) {
      return null;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
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

        // Capture current visible nodes before expansion
        final previouslyVisibleIds = _visibleNodes.map((n) => n.id).toSet();

        // Trigger expansion animation
        expansionController.forward(from: 0.0);

        setState(() {
          node.isExpanded = !node.isExpanded;
          _isExpanding = node.isExpanded; // Track expansion direction

          // For collapse: temporarily add disappearing nodes to visibility
          // This allows them to animate out
          if (!node.isExpanded) {
            // We're collapsing - keep old visibility for now
            _rebuildVisibility();
            final nowVisibleIds = _visibleNodes.map((n) => n.id).toSet();
            _newlyAnimatedNodeIds = previouslyVisibleIds.difference(
              nowVisibleIds,
            );

            // Restore all previously visible nodes so they can animate out
            final allVisibleIds = previouslyVisibleIds.union(nowVisibleIds);
            _visibleNodes = [
              for (var id in allVisibleIds)
                if (_nodeLookup[id] != null) _nodeLookup[id]!,
            ];
            _visibleEdges = _allEdges
                .where(
                  (edge) =>
                      allVisibleIds.contains(edge.fromId) &&
                      allVisibleIds.contains(edge.toId),
                )
                .toList();
          } else {
            // We're expanding - normal visibility rebuild
            _rebuildVisibility();
            final nowVisibleIds = _visibleNodes.map((n) => n.id).toSet();
            _newlyAnimatedNodeIds = nowVisibleIds.difference(
              previouslyVisibleIds,
            );
          }

          // Calculate which edges are newly deployed
          _newlyAnimatedEdgeIds = _calculateNewlyAnimatedEdges();

          _runLayout();
          // Re-center the viewport after expansion/collapse
          // This ensures the expanded content is visible
          _autoCenterPending = true;

          // Use post-frame callback to ensure layout is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _applyAutoCenterIfNeeded();
              });
            }
          });
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

  /// Calculates parent positions for animation
  /// Maps each node to its parent's position for the slide-in animation
  /// Only includes nodes that are newly animated
  Map<String, Offset> _calculateParentPositions() {
    final parentMap = <String, Offset>{};

    for (final edge in _visibleEdges) {
      // Only animate newly visible nodes
      if (_newlyAnimatedNodeIds.contains(edge.toId)) {
        final parent = _nodeLookup[edge.fromId];
        if (parent != null) {
          parentMap[edge.toId] = parent.position;
        }
      }
    }

    return parentMap;
  }

  /// Generates a unique identifier for an edge
  /// Format: "fromId->toId"
  String _getEdgeId(MindMapEdge edge) => '${edge.fromId}->${edge.toId}';

  /// Calculates which edges are newly animated
  /// An edge is new if at least one of its endpoints is newly animated
  Set<String> _calculateNewlyAnimatedEdges() {
    final newEdges = <String>{};

    for (final edge in _visibleEdges) {
      // Edge is new if either endpoint is newly animated
      if (_newlyAnimatedNodeIds.contains(edge.fromId) ||
          _newlyAnimatedNodeIds.contains(edge.toId)) {
        newEdges.add(_getEdgeId(edge));
      }
    }

    return newEdges;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _canvasSize.width;
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : _canvasSize.height;
        final newSize = Size(width, height);

        if (newSize != _canvasSize && !_sizeUpdateScheduled) {
          _sizeUpdateScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              _sizeUpdateScheduled = false;
              return;
            }

            _sizeUpdateScheduled = false;
            setState(() {
              _canvasSize = newSize;
              if (!_hasUserPannedOrZoomed) {
                _autoCenterPending = true;
              }
              _runLayout();
            });
          });
        }

        return Listener(
          // Mouse wheel zoom support
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final scrollDelta = event.scrollDelta.dy;
              final zoomFactor = scrollDelta > 0 ? 0.9 : 1.1;

              setState(() {
                final oldScale = scale;
                scale = (scale * zoomFactor).clamp(0.3, 5.0);

                // Zoom towards cursor position
                final pointerOffset = event.localPosition;
                final scaleDelta = scale - oldScale;
                offset = Offset(
                  offset.dx -
                      (pointerOffset.dx - offset.dx) * scaleDelta / oldScale,
                  offset.dy -
                      (pointerOffset.dy - offset.dy) * scaleDelta / oldScale,
                );

                _hasUserPannedOrZoomed = true;
              });
            }
          },
          child: GestureDetector(
            onScaleStart: (details) {
              lastFocalPoint = details.focalPoint;
              _hasUserPannedOrZoomed = true;
            },
            onScaleUpdate: (details) {
              setState(() {
                // Handle zoom with pinch gestures
                if (details.scale != 1.0) {
                  final oldScale = scale;
                  scale = (scale * details.scale).clamp(0.3, 5.0);

                  // Zoom towards focal point
                  final focalPointOffset = details.focalPoint;
                  final scaleDelta = scale - oldScale;
                  offset = Offset(
                    offset.dx -
                        (focalPointOffset.dx - offset.dx) *
                            scaleDelta /
                            oldScale,
                    offset.dy -
                        (focalPointOffset.dy - offset.dy) *
                            scaleDelta /
                            oldScale,
                  );
                }

                // Handle pan
                if (lastFocalPoint != null && details.scale == 1.0) {
                  offset += details.focalPoint - lastFocalPoint!;
                }
                lastFocalPoint = details.focalPoint;
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
                  parentPositions: _calculateParentPositions(),
                  expansionProgress: _expansionProgress,
                  edgeOpacity: _edgeOpacity,
                  newlyAnimatedEdgeIds: _newlyAnimatedEdgeIds,
                  isExpanding: _isExpanding,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }
}
