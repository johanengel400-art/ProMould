// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:promould/main.dart';

void main() {
  testWidgets('ProMould app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProMouldApp());

    // Verify that login screen is shown
    expect(find.text('ProMould'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
