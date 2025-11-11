// test/widget/empty_state_test.dart
// Widget tests for empty state components

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promould/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget', () {
    testWidgets('displays message and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: 'No data available',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: 'No data',
              subtitle: 'Try adding some items',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('No data'), findsOneWidget);
      expect(find.text('Try adding some items'), findsOneWidget);
    });

    testWidgets('displays action button when provided',
        (WidgetTester tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: 'No items',
              icon: Icons.inbox,
              actionLabel: 'Add Item',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('does not display action button when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              message: 'No items',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('NoMachinesState Widget', () {
    testWidgets('displays correct message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoMachinesState(),
          ),
        ),
      );

      expect(find.text('No Machines Found'), findsOneWidget);
      expect(
          find.text('Add your first machine to get started'), findsOneWidget);
    });
  });

  group('NoJobsState Widget', () {
    testWidgets('displays correct message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoJobsState(),
          ),
        ),
      );

      expect(find.text('No Jobs Found'), findsOneWidget);
      expect(find.text('Create a job to start production'), findsOneWidget);
    });
  });

  group('NoIssuesState Widget', () {
    testWidgets('displays positive message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoIssuesState(),
          ),
        ),
      );

      expect(find.text('No Issues'), findsOneWidget);
      expect(find.text('Everything is running smoothly!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
