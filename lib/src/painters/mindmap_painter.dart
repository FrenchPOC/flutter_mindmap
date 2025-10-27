import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';

/// Custom painter for rendering the mind map
///
/// Draws nodes as rounded rectangles with labels and edges as lines
class MindMapPainter extends CustomPainter {
  /// List of nodes to render
  final List<MindMapNode> nodes;

  /// List of edges to render
  final List<MindMapEdge> edges;

  /// Pan offset for the canvas
  final Offset offset;

  /// Zoom scale for the canvas
  final double scale;

  /// Mapping of node ids to their direct children ids.
  final Map<String, List<String>> childrenMap;

  /// Maximum width for node labels
  static const double maxWidth = 250.0;

  /// Padding inside nodes
  static const double padding = 16.0;

  /// Border radius for rounded corners
  static const double borderRadius = 12.0;

  MindMapPainter({
    required this.nodes,
    required this.edges,
    required this.offset,
    required this.scale,
    required this.childrenMap,
  }) {
    // Calculate sizes for all nodes
    _calculateNodeSizes();
  }

  /// Calculates and caches the size of each node based on its label
  void _calculateNodeSizes() {
    for (var node in nodes) {
      if (node.size == null) {
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

        textPainter.layout(maxWidth: maxWidth - padding * 2);

        node.size = Size(
          min(textPainter.width + padding * 2, maxWidth),
          textPainter.height + padding * 2,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw edges
    final edgePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var edge in edges) {
      final from = nodes.firstWhere((n) => n.id == edge.fromId);
      final to = nodes.firstWhere((n) => n.id == edge.toId);

      // Calculate edge start and end points at the edge of rectangles
      final fromRect = Rect.fromCenter(
        center: from.position,
        width: from.size?.width ?? 100,
        height: from.size?.height ?? 60,
      );
      final toRect = Rect.fromCenter(
        center: to.position,
        width: to.size?.width ?? 100,
        height: to.size?.height ?? 60,
      );

      // Find intersection points
      final startPoint = _getIntersectionPoint(
        fromRect,
        from.position,
        to.position,
      );
      final endPoint = _getIntersectionPoint(
        toRect,
        to.position,
        from.position,
      );

      canvas.drawLine(startPoint, endPoint, edgePaint);
    }

    // Draw nodes
    for (var node in nodes) {
      final nodeSize = node.size ?? const Size(100, 60);
      final rect = Rect.fromCenter(
        center: node.position,
        width: nodeSize.width,
        height: nodeSize.height,
      );

      // Draw rounded rectangle with shadow
      final shadowPath = RRect.fromRectAndRadius(
        rect.translate(2, 2),
        const Radius.circular(borderRadius),
      );
      canvas.drawRRect(
        shadowPath,
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );

      // Draw rounded rectangle
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(borderRadius),
      );

      canvas.drawRRect(rrect, Paint()..color = node.color);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, borderPaint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: null,
      );

      textPainter.layout(maxWidth: maxWidth - padding * 2);

      final textOffset = Offset(
        node.position.dx - textPainter.width / 2,
        node.position.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      final hasChildren = (childrenMap[node.id]?.isNotEmpty ?? false);
      if (hasChildren) {
        _paintExpansionIndicator(canvas, rect, node);
      }
    }

    canvas.restore();
  }

  /// Calculates the intersection point between a line and a rectangle
  ///
  /// Used to find where edges should connect to node borders
  Offset _getIntersectionPoint(Rect rect, Offset center, Offset target) {
    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;

    if (dx == 0 && dy == 0) return center;

    final angle = atan2(dy, dx);
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;

    // Check which edge the line intersects
    final tanAngle = tan(angle).abs();

    if (tanAngle < halfHeight / halfWidth) {
      // Intersects left or right edge
      final x = dx > 0 ? halfWidth : -halfWidth;
      final y = x * tan(angle);
      return Offset(center.dx + x, center.dy + y);
    } else {
      // Intersects top or bottom edge
      final y = dy > 0 ? halfHeight : -halfHeight;
      final x = y / tan(angle);
      return Offset(center.dx + x, center.dy + y);
    }
  }

  void _paintExpansionIndicator(Canvas canvas, Rect rect, MindMapNode node) {
    const indicatorRadius = 10.0;
    const paddingFromEdge = 12.0;
    final indicatorCenter = Offset(
      rect.right - paddingFromEdge,
      rect.bottom - paddingFromEdge,
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorCenter, indicatorRadius, backgroundPaint);

    final lineColor = node.color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.black54;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(indicatorCenter.dx - indicatorRadius * 0.5, indicatorCenter.dy),
      Offset(indicatorCenter.dx + indicatorRadius * 0.5, indicatorCenter.dy),
      linePaint,
    );

    if (!node.isExpanded) {
      canvas.drawLine(
        Offset(indicatorCenter.dx, indicatorCenter.dy - indicatorRadius * 0.5),
        Offset(indicatorCenter.dx, indicatorCenter.dy + indicatorRadius * 0.5),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindMapPainter oldDelegate) {
    return true;
  }
}
