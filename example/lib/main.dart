import 'package:flutter/material.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const MindMapDemo({Key? key}) : super(key: key);

  @override
  State<MindMapDemo> createState() => _MindMapDemoState();
}

class _MindMapDemoState extends State<MindMapDemo> {
  bool useTreeLayout = false;

  // Example JSON data format 1: Explicit nodes and edges
  final String exampleData1 = jsonEncode({
    "nodes": [
      {"id": "1", "label": "Machine Learning Overview", "color": "#FF6B6B"},
      {
        "id": "2",
        "label":
            "Supervised Learning: Training models with labeled data to predict outcomes",
        "color": "#4ECDC4",
      },
      {
        "id": "3",
        "label":
            "Unsupervised Learning: Finding patterns in unlabeled data through clustering and dimensionality reduction",
        "color": "#45B7D1",
      },
      {"id": "4", "label": "Reinforcement Learning", "color": "#96CEB4"},
      {
        "id": "5",
        "label":
            "Deep neural networks with multiple layers that can learn hierarchical representations of data",
        "color": "#FFEAA7",
      },
    ],
    "edges": [
      {"from": "1", "to": "2"},
      {"from": "1", "to": "3"},
      {"from": "1", "to": "4"},
      {"from": "2", "to": "5"},
    ],
  });

  // Example JSON data format 2: Nested structure with children
  final String exampleData2 = jsonEncode([
    {
      "id": "1",
      "label": "Project Planning",
      "color": "#FF6B6B",
      "children": [
        {
          "id": "2",
          "label":
              "Requirements: Gather stakeholder needs, define scope, create user stories, and establish acceptance criteria",
          "color": "#4ECDC4",
          "children": [
            {
              "id": "5",
              "label":
                  "Functional and non-functional requirements documentation",
              "color": "#FFEAA7",
            },
          ],
        },
        {
          "id": "3",
          "label": "Design Phase: Architecture, UI/UX, and database schema",
          "color": "#45B7D1",
        },
        {"id": "4", "label": "Implementation", "color": "#96CEB4"},
      ],
    },
  ]);

  String currentData = '';

  @override
  void initState() {
    super.initState();
    currentData = exampleData1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter MindMap Demo'),
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
            child: Center(child: Text('Tree Layout')),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentData = exampleData1;
                    });
                  },
                  child: const Text('Machine Learning Map'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentData = exampleData2;
                    });
                  },
                  child: const Text('Project Planning Map'),
                ),
              ],
            ),
          ),
          Expanded(
            child: MindMapWidget(
              key: ValueKey(currentData + useTreeLayout.toString()),
              jsonData: currentData,
              useTreeLayout: useTreeLayout,
            ),
          ),
        ],
      ),
    );
  }
}
