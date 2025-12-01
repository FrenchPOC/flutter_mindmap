import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mindmap_example/main.dart';
import 'package:flutter_mindmap/flutter_mindmap.dart';

void main() {
  testWidgets('Bidirectional layout smart expansion test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: MindMapDemo()));

    // Verify initial state (Tree layout, Expand All = false)
    expect(find.text('Tree Layout'), findsOneWidget);
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Toggle "Expand All" to true
    await tester.tap(switchFinder);
    await tester.pump();
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    // Toggle back to false for the rest of the test
    await tester.tap(switchFinder);
    await tester.pump();
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    // Change layout to Bidirectional
    // Find the dropdown
    final dropdownFinder = find.byType(DropdownButton<MindMapLayoutType>);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap "Bidirectional"
    await tester.tap(find.text('Bidirectional').last);
    await tester.pumpAndSettle();

    // Verify MindMapWidget properties
    final mindMapFinder = find.byType(MindMapWidget);
    expect(mindMapFinder, findsOneWidget);

    final mindMapWidget = tester.widget<MindMapWidget>(mindMapFinder);

    // Check layout type
    expect(mindMapWidget.layoutType, MindMapLayoutType.bidirectional);

    // Check expandAllNodesByDefault is false
    expect(mindMapWidget.expandAllNodesByDefault, isFalse);

    // Check initiallyExpandedNodeIds
    // Based on the default JSON in main.dart:
    // Root id: "1"
    // Children ids: "2", "3"
    final expectedIds = {'1', '2', '3'};
    expect(mindMapWidget.initiallyExpandedNodeIds, equals(expectedIds));
  });
}
