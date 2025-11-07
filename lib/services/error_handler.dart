// lib/services/error_handler.dart
// Centralized error handling with user-friendly messages

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'log_service.dart';

/// Centralized error handling service.
/// Provides user-friendly error messages and logs errors for debugging.
class ErrorHandler {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  /// Handle any error with context and optional user message
  static void handle(
    dynamic error, {
    String? context,
    String? userMessage,
    StackTrace? stackTrace,
    bool showToUser = true,
  }) {
    // Log the error
    LogService.error(
      context != null ? 'Error in $context' : 'Error occurred',
      error,
      stackTrace,
    );

    // Show user-friendly message
    if (showToUser) {
      final message = userMessage ?? _getUserFriendlyMessage(error);
      showError(message);
    }
  }

  /// Get user-friendly error message based on error type
  static String _getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    } else if (error is HiveError) {
      return 'Data storage error. Please restart the app.';
    } else if (error is NetworkException) {
      return 'Network error. Please check your internet connection.';
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is AuthenticationException) {
      return error.message;
    } else if (error is PermissionException) {
      return 'Permission denied. Please check your access rights.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get Firebase-specific error messages
  static String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Requested data not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'data-loss':
        return 'Data loss detected. Please contact support.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      default:
        return 'Connection issue. Please check your internet.';
    }
  }

  /// Show error message to user
  static void showError(String message, {Duration? duration}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success message to user
  static void showSuccess(String message, {Duration? duration}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00D26A),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning message to user
  static void showWarning(String message, {Duration? duration}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFD166),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info message to user
  static void showInfo(String message, {Duration? duration}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CC9F0),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle async operations with automatic error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    String? successMessage,
    String? errorMessage,
    bool showSuccess = false,
  }) async {
    try {
      final result = await operation();
      if (showSuccess && successMessage != null) {
        showSuccess(successMessage);
      }
      return result;
    } catch (e, stackTrace) {
      handle(
        e,
        context: context,
        userMessage: errorMessage,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

// Custom exception classes

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  @override
  String toString() => message;
}

class PermissionException implements Exception {
  final String message;
  PermissionException([this.message = 'Permission denied']);
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Operation timed out']);
  @override
  String toString() => message;
}
