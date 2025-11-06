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

  /// Mapping of node ids to their parent positions (for animation)
  final Map<String, Offset> parentPositions;

  /// Animation progress for expansion/collapse (0.0 to 1.0)
  final double expansionProgress;

  /// Edge fade-in opacity (0.0 to 1.0) - appears after node animation
  final double edgeOpacity;

  /// Set of edge IDs that are newly animated
  /// Format: "fromId->toId"
  /// Only edges in this set will fade in; others stay at full opacity
  final Set<String> newlyAnimatedEdgeIds;

  /// Maximum width for node labels
  static const double maxWidth = 250.0;

  /// Padding inside nodes
  static const double padding = 16.0;

  /// Radius of the expand/collapse indicator button
  static const double indicatorRadius = 10.0;

  /// Distance of the indicator button from the node edge
  static const double indicatorPaddingFromEdge = 12.0;

  /// Border radius for rounded corners
  static const double borderRadius = 12.0;

  MindMapPainter({
    required this.nodes,
    required this.edges,
    required this.parentPositions,
    required this.offset,
    required this.scale,
    required this.childrenMap,
    this.expansionProgress = 1.0,
    this.edgeOpacity = 1.0,
    this.newlyAnimatedEdgeIds = const {},
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
            style: TextStyle(
              color: Colors.grey.shade900,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: null,
        );

        textPainter.layout(maxWidth: maxWidth - padding * 2);

        var width = min(textPainter.width + padding * 2, maxWidth);
        var height = textPainter.height + padding * 2;

        final hasChildren = (childrenMap[node.id]?.isNotEmpty ?? false);
        if (hasChildren) {
          final extraSpace = indicatorPaddingFromEdge + indicatorRadius;
          width += extraSpace;
          height += extraSpace;
        }

        node.size = Size(width, height);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw edges with curved bezier paths (Google Notebook style)
    for (var edge in edges) {
      final from = nodes.firstWhere((n) => n.id == edge.fromId);
      final to = nodes.firstWhere((n) => n.id == edge.toId);

      // Determine opacity for this edge
      // Newly animated edges use edgeOpacity (fade in effect)
      // Already visible edges stay at full opacity (1.0)
      final edgeId = '${edge.fromId}->${edge.toId}';
      final isNewlyAnimated = newlyAnimatedEdgeIds.contains(edgeId);
      final edgeAlpha = isNewlyAnimated ? edgeOpacity : 1.0;

      final edgePaint = Paint()
        ..color = Colors.grey.shade300.withValues(alpha: edgeAlpha)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

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

      // Draw curved bezier line (horizontal emphasis for Google Notebook style)
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      // Calculate control points for smooth horizontal curve
      final horizontalDistance = (endPoint.dx - startPoint.dx).abs();
      final controlPointOffset = horizontalDistance * 0.5;

      final controlPoint1 = Offset(
        startPoint.dx + controlPointOffset,
        startPoint.dy,
      );
      final controlPoint2 = Offset(
        endPoint.dx - controlPointOffset,
        endPoint.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

      canvas.drawPath(path, edgePaint);
    }

    // Draw nodes with pill shape (Google Notebook style)
    for (var node in nodes) {
      final nodeSize = node.size ?? const Size(100, 60);

      // Animate node position from parent position to final position
      final parentPos = parentPositions[node.id] ?? node.position;
      final animatedPosition =
          Offset.lerp(parentPos, node.position, expansionProgress) ??
          node.position;

      final rect = Rect.fromCenter(
        center: animatedPosition,
        width: nodeSize.width,
        height: nodeSize.height,
      );

      // Create pill shape with fully rounded ends
      final pillRadius = Radius.circular(nodeSize.height / 2);
      final rrect = RRect.fromRectAndRadius(rect, pillRadius);

      // Softer, lighter colors for Google Notebook style
      final nodeColor = _lightenColor(node.color, 0.3);

      // Full opacity - position animation instead of fade
      canvas.drawRRect(rrect, Paint()..color = nodeColor);

      // Subtle border
      final borderPaint = Paint()
        ..color = _darkenColor(node.color, 0.1)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, borderPaint);

      // Draw label with darker text for better readability on light backgrounds
      // Use dark text by default since lightened colors are light
      final textColor = Colors.grey.shade900;

      final textPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: null,
      );

      textPainter.layout(maxWidth: maxWidth - padding * 2);

      final textOffset = Offset(
        animatedPosition.dx - textPainter.width / 2,
        animatedPosition.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      final hasChildren = (childrenMap[node.id]?.isNotEmpty ?? false);
      if (hasChildren) {
        _paintExpansionIndicator(canvas, rect, node);
      }
    }

    canvas.restore();
  }

  /// Lightens a color by the given factor (0.0 - 1.0)
  Color _lightenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darkens a color by the given factor (0.0 - 1.0)
  Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
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
    // Position indicator on the right edge for horizontal layout
    final indicatorCenter = Offset(
      rect.right + indicatorPaddingFromEdge + indicatorRadius,
      rect.center.dy,
    );

    // Softer background matching Google Notebook style
    final backgroundColor = _lightenColor(node.color, 0.4);
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorCenter, indicatorRadius, backgroundPaint);

    // Border for the indicator
    final borderPaint = Paint()
      ..color = _darkenColor(node.color, 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(indicatorCenter, indicatorRadius, borderPaint);

    // Icon color
    final iconColor = _darkenColor(node.color, 0.3);
    final linePaint = Paint()
      ..color = iconColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw + or - icon
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
