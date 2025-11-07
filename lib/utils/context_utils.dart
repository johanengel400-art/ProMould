// lib/utils/context_utils.dart
// Context utilities for safe async operations

import 'package:flutter/material.dart';

/// Safe navigation utilities that check if context is still mounted
class SafeContext {
  /// Safely pop navigator if context is still mounted
  static void pop(BuildContext context, [dynamic result]) {
    if (context.mounted) {
      Navigator.pop(context, result);
    }
  }

  /// Safely push route if context is still mounted
  static Future<T?>? push<T>(BuildContext context, Route<T> route) {
    if (context.mounted) {
      return Navigator.push(context, route);
    }
    return null;
  }

  /// Safely push replacement route if context is still mounted
  static Future<T?>? pushReplacement<T, TO>(
    BuildContext context,
    Route<T> route, {
    TO? result,
  }) {
    if (context.mounted) {
      return Navigator.pushReplacement(context, route, result: result);
    }
    return null;
  }

  /// Safely show dialog if context is still mounted
  static Future<T?>? showDialog<T>(
    BuildContext context,
    Widget Function(BuildContext) builder,
  ) {
    if (context.mounted) {
      return showDialog<T>(
        context: context,
        builder: builder,
      );
    }
    return null;
  }

  /// Safely show snackbar if context is still mounted
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  /// Safely show bottom sheet if context is still mounted
  static Future<T?>? showBottomSheet<T>(
    BuildContext context,
    Widget Function(BuildContext) builder,
  ) {
    if (context.mounted) {
      return showModalBottomSheet<T>(
        context: context,
        builder: builder,
      );
    }
    return null;
  }
}

/// Extension on BuildContext for safe async operations
extension SafeContextExtension on BuildContext {
  /// Check if context is still mounted
  bool get isMounted => mounted;

  /// Safely pop if mounted
  void safePop([dynamic result]) {
    if (mounted) {
      Navigator.pop(this, result);
    }
  }

  /// Safely push if mounted
  Future<T?>? safePush<T>(Route<T> route) {
    if (mounted) {
      return Navigator.push(this, route);
    }
    return null;
  }

  /// Safely push replacement if mounted
  Future<T?>? safePushReplacement<T, TO>(Route<T> route, {TO? result}) {
    if (mounted) {
      return Navigator.pushReplacement(this, route, result: result);
    }
    return null;
  }

  /// Safely show snackbar if mounted
  void safeShowSnackBar(SnackBar snackBar) {
    if (mounted) {
      ScaffoldMessenger.of(this).showSnackBar(snackBar);
    }
  }
}
