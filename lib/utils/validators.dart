// lib/utils/validators.dart
// Input validation utilities for forms

/// Validation utilities for form inputs.
/// Provides reusable validators for common input types.
class Validators {
  /// Validate required field
  static String? required(dynamic value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value is String && value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate positive integer
  static String? positiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  /// Validate non-negative integer (allows 0)
  static String? nonNegativeInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    
    return null;
  }

  /// Validate positive double
  static String? positiveDouble(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  /// Validate non-negative double (allows 0)
  static String? nonNegativeDouble(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    
    return null;
  }

  /// Validate number within range
  static String? numberInRange(
    String? value,
    String fieldName,
    num min,
    num max,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = num.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }
    
    return null;
  }

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate username (alphanumeric, underscore, hyphen)
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscore, and hyphen';
    }
    
    return null;
  }

  /// Validate password strength
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validate strong password (with requirements)
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validate phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove common formatting characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleaned.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (!RegExp(r'^[0-9+]+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits and +';
    }
    
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, String fieldName, int minLength) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, String fieldName, int maxLength) {
    if (value == null) return null;
    
    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  /// Validate alphanumeric
  static String? alphanumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return '$fieldName can only contain letters and numbers';
    }
    
    return null;
  }

  /// Validate date is not in the past
  static String? notPastDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);
    
    if (selectedDate.isBefore(today)) {
      return '$fieldName cannot be in the past';
    }
    
    return null;
  }

  /// Validate date is not in the future
  static String? notFutureDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);
    
    if (selectedDate.isAfter(today)) {
      return '$fieldName cannot be in the future';
    }
    
    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Validate percentage (0-100)
  static String? percentage(String? value, String fieldName) {
    return numberInRange(value, fieldName, 0, 100);
  }

  /// Validate cycle time (reasonable range for injection molding)
  static String? cycleTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cycle time is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Cycle time must be a valid number';
    }
    
    if (number < 1) {
      return 'Cycle time must be at least 1 second';
    }
    
    if (number > 3600) {
      return 'Cycle time seems too long (max 1 hour)';
    }
    
    return null;
  }

  /// Validate cavity count
  static String? cavities(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of cavities is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Number of cavities must be a valid number';
    }
    
    if (number < 1) {
      return 'Must have at least 1 cavity';
    }
    
    if (number > 128) {
      return 'Number of cavities seems too high (max 128)';
    }
    
    return null;
  }
}
