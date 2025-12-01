/*
 * Flutter MindMap Library
 *
 * A library for rendering interactive mind maps from JSON data.
 * Supports force-directed and tree layout algorithms with pan and zoom gestures.
 *
 * Features:
 * - Parse mind map data from JSON
 * - Force-directed physics-based layout
 * - Hierarchical tree layout
 * - Interactive pan and zoom
 * - Customizable node colors
 * - Automatic text wrapping and sizing
 *
 * Usage:
 *
 * ```dart
 * import 'package:flutter_mindmap/flutter_mindmap.dart';
 *
 * MindMapWidget(
 *   jsonData: '''
 *   {
 *     "nodes": [
 *       {"id": "1", "label": "Root", "color": "#FF6B6B"},
 *       {"id": "2", "label": "Child 1", "color": "#4ECDC4"}
 *     ],
 *     "edges": [
 *       {"from": "1", "to": "2"}
 *     ]
 *   }
 *   ''',
 *   useTreeLayout: false,
 * );
 * ```
 */

// Export models
export 'src/models/mindmap_node.dart';
export 'src/models/mindmap_edge.dart';

// Export layouts
export 'src/layouts/force_directed_layout.dart';
export 'src/layouts/tree_layout.dart';
export 'src/layouts/bidirectional_layout.dart';

// Export painters
export 'src/painters/mindmap_painter.dart';

// Export widgets
export 'src/widgets/mindmap_widget.dart';
