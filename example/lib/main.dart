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
  bool useTreeLayout = true; // Default to tree layout for horizontal display

  // Google Notebook-style example: Infrared Technology mind map
  final String infraredTechData = jsonEncode([
    {
      "id": "root",
      "label":
          "Infrared Thermography for Condition Monitoring & Fault Detection",
      "color": "#7B68EE",
      "children": [
        {
          "id": "basics",
          "label": "Infrared Technology Basics",
          "color": "#6495ED",
          "children": [
            {
              "id": "emissivity",
              "label": "Emissivity & Surface Properties",
              "color": "#87CEEB",
            },
            {
              "id": "wavelengths",
              "label": "Thermal Wavelength Ranges",
              "color": "#87CEEB",
            },
          ],
        },
        {
          "id": "measurements",
          "label": "Crucial Measurement/Imaging Factors",
          "color": "#6495ED",
          "children": [
            {
              "id": "distance",
              "label": "Distance & Resolution",
              "color": "#87CEEB",
            },
            {
              "id": "ambient",
              "label": "Ambient Conditions",
              "color": "#87CEEB",
            },
          ],
        },
        {
          "id": "monitoring",
          "label": "Applications in Condition Monitoring (CM)",
          "color": "#6495ED",
          "children": [
            {
              "id": "electrical",
              "label": "Electrical Systems",
              "color": "#87CEEB",
            },
            {
              "id": "mechanical",
              "label": "Mechanical Equipment",
              "color": "#87CEEB",
            },
            {
              "id": "buildings",
              "label": "Building Inspections",
              "color": "#87CEEB",
            },
          ],
        },
        {
          "id": "fault",
          "label": "Advanced Fault Detection in Power Systems",
          "color": "#6495ED",
          "children": [
            {
              "id": "hotspots",
              "label": "Hotspot Detection",
              "color": "#87CEEB",
            },
            {
              "id": "predictive",
              "label": "Predictive Maintenance",
              "color": "#87CEEB",
            },
          ],
        },
        {
          "id": "detection",
          "label": "Infrared Detection Methods",
          "color": "#6495ED",
          "children": [
            {
              "id": "passive",
              "label": "Passive Thermography",
              "color": "#87CEEB",
            },
            {
              "id": "active",
              "label": "Active Thermography",
              "color": "#87CEEB",
            },
          ],
        },
        {
          "id": "data",
          "label": "Thermal Imaging Data Handling",
          "color": "#6495ED",
          "children": [
            {
              "id": "processing",
              "label": "Image Processing",
              "color": "#87CEEB",
            },
            {"id": "analysis", "label": "Data Analysis", "color": "#87CEEB"},
          ],
        },
        {
          "id": "training",
          "label": "Training & Prioritization",
          "color": "#6495ED",
          "children": [
            {
              "id": "certification",
              "label": "Operator Certification",
              "color": "#87CEEB",
            },
            {
              "id": "standards",
              "label": "Industry Standards",
              "color": "#87CEEB",
            },
          ],
        },
      ],
    },
  ]);

  // Simpler example for comparison
  final String simpleData = jsonEncode([
    {
      "id": "1",
      "label": "Product Development",
      "color": "#FF6B6B",
      "children": [
        {
          "id": "2",
          "label": "Research & Discovery",
          "color": "#4ECDC4",
          "children": [
            {"id": "5", "label": "Market Analysis", "color": "#95E1D3"},
            {"id": "6", "label": "User Research", "color": "#95E1D3"},
          ],
        },
        {
          "id": "3",
          "label": "Design & Prototyping",
          "color": "#45B7D1",
          "children": [
            {"id": "7", "label": "UI/UX Design", "color": "#A8E6CF"},
            {"id": "8", "label": "Wireframes", "color": "#A8E6CF"},
          ],
        },
        {
          "id": "4",
          "label": "Development",
          "color": "#96CEB4",
          "children": [
            {"id": "9", "label": "Frontend", "color": "#C7CEEA"},
            {"id": "10", "label": "Backend", "color": "#C7CEEA"},
            {"id": "11", "label": "Testing", "color": "#C7CEEA"},
          ],
        },
      ],
    },
  ]);

  String currentData = '';

  @override
  void initState() {
    super.initState();
    currentData = infraredTechData; // Start with the infrared tech example
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter MindMap Demo - Google Notebook Style'),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interactive Mind Map Examples',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use mouse wheel to zoom, drag to pan, click nodes to expand/collapse',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          currentData = infraredTechData;
                        });
                      },
                      icon: const Icon(Icons.science),
                      label: const Text('Infrared Technology'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          currentData = simpleData;
                        });
                      },
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Product Development'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: MindMapWidget(
              key: ValueKey(currentData + useTreeLayout.toString()),
              jsonData: currentData,
              useTreeLayout: useTreeLayout,
              backgroundColor: const Color(0xFFFAFAFA),
              expandAllNodesByDefault: false,
            ),
          ),
        ],
      ),
    );
  }
}
