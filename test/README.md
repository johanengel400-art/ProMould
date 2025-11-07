# ProMould Test Suite

This directory contains the test suite for ProMould application.

## Test Structure

```
test/
├── unit/              # Unit tests for business logic
│   ├── services/      # Service layer tests
│   └── utils/         # Utility function tests
├── widget/            # Widget tests for UI components
└── integration/       # Integration tests for user flows
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/unit/utils/validators_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### View coverage report
```bash
# Install lcov (if not already installed)
# macOS: brew install lcov
# Linux: sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

## Writing Tests

### Unit Tests
Unit tests should test individual functions or methods in isolation.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:promould/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required returns error for null', () {
      expect(
        Validators.required(null, 'Field'),
        equals('Field is required'),
      );
    });
  });
}
```

### Widget Tests
Widget tests verify UI components render correctly and respond to interactions.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promould/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState displays message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(message: 'No data'),
        ),
      ),
    );

    expect(find.text('No data'), findsOneWidget);
  });
}
```

### Integration Tests
Integration tests verify complete user flows across multiple screens.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:promould/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Test login flow
    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.enterText(find.byType(TextField).last, 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Verify navigation to dashboard
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

## Test Coverage Goals

- **Unit Tests:** 80%+ coverage
- **Widget Tests:** 70%+ coverage
- **Integration Tests:** Key user flows

## Best Practices

1. **Arrange-Act-Assert Pattern**
   - Arrange: Set up test data
   - Act: Execute the code being tested
   - Assert: Verify the results

2. **Test Naming**
   - Use descriptive names: `test('returns error for invalid email')`
   - Group related tests: `group('Validators')`

3. **Mock External Dependencies**
   - Use mockito for mocking services
   - Avoid real network calls or database operations

4. **Keep Tests Fast**
   - Unit tests should run in milliseconds
   - Widget tests should run in seconds
   - Integration tests can take longer

5. **Test Edge Cases**
   - Null values
   - Empty strings
   - Boundary conditions
   - Error scenarios

## Continuous Integration

Tests are automatically run on every push via GitHub Actions. See `.github/workflows/flutter.yml` for CI configuration.

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
