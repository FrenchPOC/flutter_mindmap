# Flutter MindMap

A production-ready Flutter library for rendering interactive mind maps from JSON data with support for multiple layout algorithms.

**Version**: 0.1.0 | **License**: MIT | **Status**: ✅ Production Ready

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [JSON Formats](#json-formats)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)

---

## Features

✨ **Two Layout Algorithms**
- **Force-Directed**: Organic physics-based layout with smooth animations
- **Tree Layout**: Hierarchical structure perfect for org charts

🎨 **Fully Customizable**
- Custom node colors (hex format support)
- Automatic text sizing and wrapping
- Modern design with rounded corners and shadows
- Configurable background color and animation speed

🖱️ **Interactive & Responsive**
- Pan support (drag to move across canvas)
- Zoom support (pinch to scale, 0.5x to 3.0x)
- Smooth animations and transitions
- Responsive to gestures in real-time
- Tap nodes to collapse or expand entire branches

📦 **Flexible & Easy**
- Support for two JSON formats (explicit and nested)
- Automatic parsing of nested structures
- Complete public API exports
- Fully documented with examples

---

## Installation

### From GitHub

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_mindmap:
    git:
      url: https://github.com/FrenchPOC/flutter_mindmap.git
```

### From Local Path

```yaml
dependencies:
  flutter_mindmap:
    path: ../flutter_mindmap
```

### From pub.dev (when published)

```yaml
dependencies:
  flutter_mindmap: ^0.1.0
```

Then run:
```bash
flutter pub get
```

---

## Quick Start

### Basic Usage (5 minutes)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('My MindMap')),
        body: MindMapWidget(
          jsonData: '''
          {
            "nodes": [
              {"id": "1", "label": "Main Idea", "color": "#FF6B6B"},
              {"id": "2", "label": "Sub-idea 1", "color": "#4ECDC4"},
              {"id": "3", "label": "Sub-idea 2", "color": "#45B7D1"}
            ],
            "edges": [
              {"from": "1", "to": "2"},
              {"from": "1", "to": "3"}
            ]
          }
          ''',
        ),
      ),
    );
  }
}
```

### Run the Example

```bash
cd example
flutter pub get
flutter run
```

The example includes two datasets and a layout toggle.

---

## Usage Examples

### Example 1: Organization Chart

```dart
MindMapWidget(
  jsonData: '''
  [{
    "id": "ceo",
    "label": "CEO",
    "color": "#FF6B6B",
    "children": [
      {
        "id": "cto",
        "label": "CTO",
        "color": "#4ECDC4",
        "children": [
          {"id": "dev1", "label": "Developer 1", "color": "#FFEAA7"},
          {"id": "dev2", "label": "Developer 2", "color": "#FFEAA7"}
        ]
      }
    ]
  }]
  ''',
  useTreeLayout: true,
)
```

### Example 2: Brainstorming Map

```dart
MindMapWidget(
  jsonData: yourJsonData,
  useTreeLayout: false,  // Use organic force-directed layout
  animationDuration: Duration(seconds: 3),
)
```

### Example 3: Collapsible Tree with Defaults

```dart
MindMapWidget(
  jsonData: '''
  [{
    "id": "root",
    "label": "Root Topic",
    "children": [
      {"id": "idea-a", "label": "Idea A"},
      {"id": "idea-b", "label": "Idea B"}
    ]
  }]
  ''',
  useTreeLayout: true,
  expandAllNodesByDefault: false,
  initiallyExpandedNodeIds: {'root'},
)
```

### Example 4: Load from File

```dart
import 'package:flutter/services.dart';
import 'dart:convert';

class MindMapFromFile extends StatefulWidget {
  @override
  _MindMapFromFileState createState() => _MindMapFromFileState();
}

class _MindMapFromFileState extends State<MindMapFromFile> {
  String? jsonData;

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  Future<void> loadJsonData() async {
    final data = await rootBundle.loadString('assets/mindmap.json');
    setState(() {
      jsonData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return jsonData != null
        ? MindMapWidget(jsonData: jsonData!)
        : Center(child: CircularProgressIndicator());
  }
}
```

### Example 5: Dynamic Data from API

```dart
import 'package:http/http.dart' as http;

Future<void> fetchMindMapData() async {
  final response = await http.get(
    Uri.parse('https://api.example.com/mindmap'),
  );
  
  if (response.statusCode == 200) {
    setState(() {
      jsonData = response.body;
    });
  }
}
```

---

## JSON Formats

### Format 1: Explicit Nodes and Edges

Best for complex relationships and non-hierarchical structures.

```json
{
  "nodes": [
    {
      "id": "1",
      "label": "Machine Learning",
      "color": "#FF6B6B"
    },
    {
      "id": "2",
      "label": "Supervised Learning",
      "color": "#4ECDC4"
    },
    {
      "id": "3",
      "label": "Classification",
      "color": "#FFEAA7"
    }
  ],
  "edges": [
    {"from": "1", "to": "2"},
    {"from": "2", "to": "3"}
  ]
}
```

**Field Requirements:**
- `id`: Unique identifier (string or number)
- `label`: Displayed text (string)
- `color`: Hex color code (optional, defaults to blue)

### Format 2: Nested Structure with Children

Best for hierarchical data like org charts or taxonomies.

```json
[
  {
    "id": "1",
    "label": "Root",
    "color": "#FF6B6B",
    "children": [
      {
        "id": "2",
        "label": "Child 1",
        "color": "#4ECDC4",
        "children": [
          {
            "id": "3",
            "label": "Grandchild",
            "color": "#FFEAA7"
          }
        ]
      },
      {
        "id": "4",
        "label": "Child 2",
        "color": "#45B7D1"
      }
    ]
  }
]
```

**Automatic Conversion**: Format 2 is automatically converted to Format 1 internally.

---

## API Reference

### MindMapWidget

Main widget for displaying a mind map.

#### Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `jsonData` | `String` | JSON data for the mind map (required) | - |
| `useTreeLayout` | `bool` | Use tree layout instead of force-directed | `false` |
| `backgroundColor` | `Color` | Canvas background color | `Color(0xFFF5F5F5)` |
| `expandAllNodesByDefault` | `bool` | Expand every node on load unless overridden | `true` |
| `initiallyExpandedNodeIds` | `Set<String>?` | Node IDs that should start expanded | `null` |
| `initiallyCollapsedNodeIds` | `Set<String>?` | Node IDs that should start collapsed | `null` |
| `animationDuration` | `Duration` | Force-directed animation duration | `Duration(seconds: 2)` |

#### Example

```dart
MindMapWidget(
  jsonData: jsonString,
  useTreeLayout: true,
  backgroundColor: Colors.white,
  animationDuration: Duration(seconds: 3),
)
```

### MindMapNode

Represents a single node in the mind map.

```dart
class MindMapNode {
  final String id;                          // Unique identifier
  final String label;                       // Display text
  final List<String> childrenIds;          // IDs of child nodes
  final bool? initialExpanded;              // Explicit expansion state from JSON
  Offset position;                          // Current position
  Offset velocity;                          // Animation velocity
  Color color;                              // Node color
  bool isExpanded;                          // Expansion state
  Size? size;                               // Cached text size
}
```

**Factory Constructor:**
```dart
MindMapNode.fromJson(Map<String, dynamic> json)
```

### MindMapEdge

Represents a connection between two nodes.

```dart
class MindMapEdge {
  final String fromId;      // Source node ID
  final String toId;        // Target node ID
}
```

**Factory Constructor:**
```dart
MindMapEdge.fromJson(Map<String, dynamic> json)
```

### Layout Algorithms

Both algorithms are applied automatically based on the `useTreeLayout` parameter.

**ForceDirectedLayout**
- Physics-based positioning
- Node repulsion and edge attraction
- Continuous animation
- Best for: exploratory visualization, brainstorming

**TreeLayout**
- Hierarchical positioning
- Root at top, children distributed below
- One-time calculation
- Best for: org charts, taxonomies, static structures

---

## Architecture

### Project Structure

```
lib/
├── flutter_mindmap.dart              # Public API exports
└── src/
    ├── models/
    │   ├── mindmap_node.dart         # Node data model (70 lines)
    │   └── mindmap_edge.dart         # Edge data model (45 lines)
    ├── layouts/
    │   ├── force_directed_layout.dart # Physics algorithm (95 lines)
    │   └── tree_layout.dart          # Hierarchy algorithm (85 lines)
    ├── painters/
    │   └── mindmap_painter.dart      # Canvas rendering (220 lines)
    └── widgets/
        └── mindmap_widget.dart       # Main widget (210 lines)

example/lib/main.dart                # Complete demo app

test/models_test.dart                # Unit tests
```

### Code Statistics

- **Core Library**: ~725 lines of Dart code
- **Example App**: ~180 lines
- **Unit Tests**: ~95 lines
- **Documentation**: ~2000 lines
- **Public API Classes**: 6

### How It Works

```
JSON Input
    ↓
Parse by MindMapWidget
    ↓
Create MindMapNode and MindMapEdge lists
    ↓
Apply Layout Algorithm
    ↓
Position nodes in 2D space
    ↓
Render with MindMapPainter
    ↓
Display on Canvas with Gestures
```

---

## Performance

### Recommended Usage

| Scenario | Nodes | Layout | Notes |
|----------|-------|--------|-------|
| Small brainstorm | 10-30 | Force-Directed | Smooth animations |
| Medium mindmap | 30-100 | Force-Directed | May need tuning |
| Large mindmap | 100+ | Tree | Better performance |
| Org chart | 50+ | Tree | Perfect for this use case |

### Optimization Tips

1. **Use Tree Layout** for 100+ nodes
2. **Keep labels short** for better rendering
3. **Adjust animation duration** for performance: reduce from 2s to 1s
4. **Use consistent color scheme** for better visual performance
5. **Cache JSON data** instead of recomputing

### Performance Characteristics

- **Rendering**: CustomPaint-based (60 FPS target)
- **Memory**: Efficient node caching
- **Animation**: 60 FPS on modern devices
- **Gesture Response**: Real-time pan and zoom

---

## Customization

### Change Background Color

```dart
MindMapWidget(
  jsonData: data,
  backgroundColor: Colors.white,
)
```

### Adjust Animation Speed

```dart
MindMapWidget(
  jsonData: data,
  animationDuration: Duration(seconds: 1),  // Faster
)
```

### Recommended Color Palettes

```dart
// Harmonious pastel palette
final colors = [
  "#FF6B6B",  // Coral red
  "#4ECDC4",  // Turquoise
  "#45B7D1",  // Sky blue
  "#96CEB4",  // Mint green
  "#FFEAA7",  // Pastel yellow
  "#DFE6E9",  // Light gray
  "#74B9FF",  // Periwinkle
];
```

---

## User Interactions

The widget automatically handles:

- **Pan**: Drag with one finger to move around the canvas
- **Zoom**: Pinch with two fingers to scale (0.5x to 3.0x)
- **Animation**: Force-directed layout auto-stabilizes over time
- **Bounds**: Prevents panning/zooming beyond reasonable limits

---

## Testing

Run unit tests:

```bash
flutter test
```

**Test Coverage:**
- ✅ JSON parsing
- ✅ Model creation
- ✅ Serialization
- ✅ Edge cases

---

## Troubleshooting

### Nothing Displays

**Problem**: Mind map doesn't appear

**Solutions**:
- Verify JSON is valid (use JSON validator)
- Ensure node IDs in edges match node IDs
- Check that `jsonData` is not empty
- Verify widget has space to render

### Animation Too Fast/Slow

**Problem**: Animation speed doesn't match expectations

**Solutions**:
- Adjust `animationDuration` parameter
- Use `useTreeLayout: true` to disable animation
- Reduce animation duration on weak devices

### Nodes Overlap

**Problem**: Nodes are positioned on top of each other

**Solutions**:
- Switch to `useTreeLayout: true`
- Use smaller labels for tighter spacing
- Increase number of nodes to spread them out

### Layout Looks Wrong

**Problem**: Nodes not positioned as expected

**Solutions**:
- Verify JSON format (explicit vs nested)
- Check node IDs for typos
- Try switching layout algorithm
- Ensure all edge references exist

---

## Future Enhancements

Planned features for future versions:

- [ ] Additional layout algorithms (radial, circular, hierarchical)
- [ ] Node click events and callbacks
- [ ] Custom node rendering
- [ ] Theme system with preset themes
- [ ] Performance optimization for 1000+ nodes
- [ ] Accessibility improvements
- [ ] Dark mode support
- [ ] Export to image/SVG

---

## Contributing

Contributions are welcome! Feel free to:
- Report bugs on GitHub
- Propose new features with pull requests
- Improve documentation
- Add more examples

---

## License

MIT License - Free for commercial and personal use. See [LICENSE](LICENSE) file for details.

---

## About

**Flutter MindMap** is a professional-grade library for visualizing hierarchical data and mind maps in Flutter applications.

**Created**: October 27, 2025
**Status**: ✅ Production Ready
**Maintenance**: Active

---

## Version History

### 0.1.0 (October 27, 2025)
- Initial release
- Force-directed layout algorithm
- Tree layout algorithm
- Interactive pan and zoom
- Two JSON format support
- Complete documentation
- Example application
- Unit tests

For detailed changelog, see [CHANGELOG.md](CHANGELOG.md) in the repository.
