// test/unit/utils/validators_test.dart
// Unit tests for validation utilities

import 'package:flutter_test/flutter_test.dart';
import 'package:promould/utils/validators.dart';

void main() {
  group('Validators', () {
    group('required', () {
      test('returns error for null value', () {
        expect(
          Validators.required(null, 'Field'),
          equals('Field is required'),
        );
      });

      test('returns error for empty string', () {
        expect(
          Validators.required('', 'Field'),
          equals('Field is required'),
        );
      });

      test('returns error for whitespace only', () {
        expect(
          Validators.required('   ', 'Field'),
          equals('Field is required'),
        );
      });

      test('returns null for valid value', () {
        expect(
          Validators.required('value', 'Field'),
          isNull,
        );
      });
    });

    group('positiveInteger', () {
      test('returns error for null', () {
        expect(
          Validators.positiveInteger(null, 'Count'),
          equals('Count is required'),
        );
      });

      test('returns error for empty string', () {
        expect(
          Validators.positiveInteger('', 'Count'),
          equals('Count is required'),
        );
      });

      test('returns error for non-numeric', () {
        expect(
          Validators.positiveInteger('abc', 'Count'),
          equals('Count must be a valid number'),
        );
      });

      test('returns error for zero', () {
        expect(
          Validators.positiveInteger('0', 'Count'),
          equals('Count must be greater than 0'),
        );
      });

      test('returns error for negative', () {
        expect(
          Validators.positiveInteger('-5', 'Count'),
          equals('Count must be greater than 0'),
        );
      });

      test('returns null for positive integer', () {
        expect(
          Validators.positiveInteger('10', 'Count'),
          isNull,
        );
      });
    });

    group('email', () {
      test('returns error for null', () {
        expect(
          Validators.email(null),
          equals('Email is required'),
        );
      });

      test('returns error for invalid format', () {
        expect(
          Validators.email('invalid'),
          equals('Please enter a valid email address'),
        );
      });

      test('returns error for missing @', () {
        expect(
          Validators.email('test.com'),
          equals('Please enter a valid email address'),
        );
      });

      test('returns error for missing domain', () {
        expect(
          Validators.email('test@'),
          equals('Please enter a valid email address'),
        );
      });

      test('returns null for valid email', () {
        expect(
          Validators.email('test@example.com'),
          isNull,
        );
      });
    });

    group('cycleTime', () {
      test('returns error for null', () {
        expect(
          Validators.cycleTime(null),
          equals('Cycle time is required'),
        );
      });

      test('returns error for non-numeric', () {
        expect(
          Validators.cycleTime('abc'),
          equals('Cycle time must be a valid number'),
        );
      });

      test('returns error for too small', () {
        expect(
          Validators.cycleTime('0.5'),
          equals('Cycle time must be at least 1 second'),
        );
      });

      test('returns error for too large', () {
        expect(
          Validators.cycleTime('4000'),
          equals('Cycle time seems too long (max 1 hour)'),
        );
      });

      test('returns null for valid cycle time', () {
        expect(
          Validators.cycleTime('30'),
          isNull,
        );
      });
    });

    group('cavities', () {
      test('returns error for null', () {
        expect(
          Validators.cavities(null),
          equals('Number of cavities is required'),
        );
      });

      test('returns error for zero', () {
        expect(
          Validators.cavities('0'),
          equals('Must have at least 1 cavity'),
        );
      });

      test('returns error for too many', () {
        expect(
          Validators.cavities('200'),
          equals('Number of cavities seems too high (max 128)'),
        );
      });

      test('returns null for valid cavity count', () {
        expect(
          Validators.cavities('8'),
          isNull,
        );
      });
    });

    group('percentage', () {
      test('returns error for negative', () {
        expect(
          Validators.percentage('-5', 'Rate'),
          equals('Rate must be between 0 and 100'),
        );
      });

      test('returns error for over 100', () {
        expect(
          Validators.percentage('150', 'Rate'),
          equals('Rate must be between 0 and 100'),
        );
      });

      test('returns null for valid percentage', () {
        expect(
          Validators.percentage('75', 'Rate'),
          isNull,
        );
      });

      test('returns null for 0', () {
        expect(
          Validators.percentage('0', 'Rate'),
          isNull,
        );
      });

      test('returns null for 100', () {
        expect(
          Validators.percentage('100', 'Rate'),
          isNull,
        );
      });
    });
  });
}
