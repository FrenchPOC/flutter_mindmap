import 'package:flutter/material.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MindMap Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MindMapDemo(),
    );
  }
}

class MindMapDemo extends StatefulWidget {
  const MindMapDemo({super.key});

  @override
  State<MindMapDemo> createState() => _MindMapDemoState();
}

class _MindMapDemoState extends State<MindMapDemo> {
  bool useTreeLayout = true;
  late TextEditingController _jsonController;
  String currentData = '';
  String? errorMessage;

  // Example JSON for initial value
  static const String exampleJson = '''[
  {
    "id": "1",
    "label": "Main Topic",
    "color": "#FF6B6B",
    "children": [
      {
        "id": "2",
        "label": "Subtopic A",
        "color": "#4ECDC4",
        "children": [
          {"id": "5", "label": "Item A1", "color": "#95E1D3"},
          {"id": "6", "label": "Item A2", "color": "#95E1D3"}
        ]
      },
      {
        "id": "3",
        "label": "Subtopic B",
        "color": "#45B7D1",
        "children": [
          {"id": "7", "label": "Item B1", "color": "#A8E6CF"},
          {"id": "8", "label": "Item B2", "color": "#A8E6CF"}
        ]
      }
    ]
  }
]''';

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: exampleJson);
    _parseAndDisplayJson();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _parseAndDisplayJson() {
    try {
      final decoded = jsonDecode(_jsonController.text);
      // Validate it's either a list (hierarchical format) or a map with nodes/edges
      if (decoded is List) {
        // Hierarchical format: [{id, label, children: [...]}]
        setState(() {
          currentData = _jsonController.text;
          errorMessage = null;
        });
      } else if (decoded is Map && decoded['nodes'] != null) {
        // Graph format: {nodes: [...], edges: [...]}
        setState(() {
          currentData = _jsonController.text;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage =
              'JSON must be either:\n'
              '• An array with hierarchical nodes (children)\n'
              '• An object with "nodes" and "edges" arrays';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Invalid JSON: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter MindMap - JSON Editor'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Switch(
            value: useTreeLayout,
            onChanged: (value) {
              setState(() {
                useTreeLayout = value;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text('Tree Layout', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel: JSON input
          SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  color: Colors.grey.shade200,
                  child: const Text(
                    'Enter JSON Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _jsonController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste your JSON here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.red.shade100,
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _parseAndDisplayJson,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Display MindMap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const VerticalDivider(width: 1, thickness: 1),
          // Right panel: MindMap display
          Expanded(
            child: currentData.isEmpty
                ? const Center(
                    child: Text(
                      'Enter valid JSON and click "Display MindMap"',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : MindMapWidget(
                    key: ValueKey(currentData + useTreeLayout.toString()),
                    jsonData: currentData,
                    useTreeLayout: useTreeLayout,
                    backgroundColor: const Color(0xFFFAFAFA),
                    expandAllNodesByDefault: true,
                    edgeColor: Colors.blueGrey,
                    tooltipBackgroundColor: Colors.deepPurple.withOpacity(0.9),
                    tooltipTextColor: Colors.white,
                    tooltipTextSize: 14.0,
                    tooltipBorderRadius: 10.0,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    tooltipMaxWidth: 280.0,
                  ),
          ),
        ],
      ),
    );
  }
}
