# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-10-28

### Added
- Tap-to-toggle expand/collapse behavior for nodes with children, including visual plus/minus indicators
- `expandAllNodesByDefault`, `initiallyExpandedNodeIds`, and `initiallyCollapsedNodeIds` widget options to control initial tree visibility
- Support for `isExpanded`, `expanded`, and `collapsed` flags in node JSON definitions to override default expansion state

### Changed
- Mind map rendering now hides collapsed subtrees and recalculates layout after expansion state changes
- Example application highlights expanded/collapsed presets for different data sets

## [0.1.0] - 2025-10-27

### Added
- `MindMapWidget` - Main widget for displaying interactive mind maps
- Two layout algorithms:
  - Force-directed (physics-based, organic layout)
  - Tree layout (hierarchical structure)
- Interactive features:
  - Pan (drag to move)
  - Zoom (pinch to scale, 0.5x to 3.0x)
  - Smooth animations
- Data models:
  - `MindMapNode` - Represents a mind map node
  - `MindMapEdge` - Represents a connection between nodes
- Support for two JSON formats:
  - Explicit nodes and edges
  - Nested structure with children
- Custom rendering with:
  - Rounded rectangle nodes
  - Drop shadows
  - Automatic text sizing
  - Smart connection lines
- Complete documentation in README.md
- Example application with demo data
- Unit tests for data models

[0.1.1]: https://github.com/yourusername/flutter_mindmap/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/yourusername/flutter_mindmap/releases/tag/v0.1.0
