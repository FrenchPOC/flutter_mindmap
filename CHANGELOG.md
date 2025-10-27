# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/yourusername/flutter_mindmap/releases/tag/v0.1.0
