// lib/widgets/confirmation_dialog.dart
// Reusable confirmation dialogs

import 'package:flutter/material.dart';

/// Confirmation dialog utilities
class ConfirmationDialog {
  /// Show a generic confirmation dialog
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121821),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDangerous ? const Color(0xFFFF6B6B) : const Color(0xFF4CC9F0),
                size: 28,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? 
                (isDangerous ? const Color(0xFFFF6B6B) : const Color(0xFF4CC9F0)),
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show delete confirmation dialog
  static Future<bool> confirmDelete({
    required BuildContext context,
    required String itemName,
    String? additionalMessage,
  }) async {
    return await show(
      context: context,
      title: 'Delete $itemName?',
      message: additionalMessage ?? 
        'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      isDangerous: true,
    );
  }

  /// Show discard changes confirmation
  static Future<bool> confirmDiscard({
    required BuildContext context,
  }) async {
    return await show(
      context: context,
      title: 'Discard Changes?',
      message: 'You have unsaved changes. Are you sure you want to discard them?',
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      icon: Icons.warning_amber_outlined,
      isDangerous: true,
    );
  }

  /// Show logout confirmation
  static Future<bool> confirmLogout({
    required BuildContext context,
  }) async {
    return await show(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      icon: Icons.logout,
      isDangerous: false,
    );
  }

  /// Show stop job confirmation
  static Future<bool> confirmStopJob({
    required BuildContext context,
    required String jobName,
  }) async {
    return await show(
      context: context,
      title: 'Stop Job?',
      message: 'Are you sure you want to stop "$jobName"? Progress will be saved.',
      confirmText: 'Stop Job',
      cancelText: 'Cancel',
      icon: Icons.stop_circle_outlined,
      confirmColor: const Color(0xFFFFD166),
    );
  }

  /// Show machine breakdown confirmation
  static Future<bool> confirmBreakdown({
    required BuildContext context,
    required String machineName,
  }) async {
    return await show(
      context: context,
      title: 'Report Breakdown?',
      message: 'Mark "$machineName" as broken down? This will stop all running jobs.',
      confirmText: 'Report Breakdown',
      cancelText: 'Cancel',
      icon: Icons.build_circle_outlined,
      isDangerous: true,
    );
  }

  /// Show quality hold confirmation
  static Future<bool> confirmQualityHold({
    required BuildContext context,
    required String reason,
  }) async {
    return await show(
      context: context,
      title: 'Place Quality Hold?',
      message: 'Place a quality hold for: $reason\n\nThis will stop production until resolved.',
      confirmText: 'Place Hold',
      cancelText: 'Cancel',
      icon: Icons.block,
      isDangerous: true,
    );
  }

  /// Show mould change confirmation
  static Future<bool> confirmMouldChange({
    required BuildContext context,
    required String machineName,
    required String newMould,
  }) async {
    return await show(
      context: context,
      title: 'Start Mould Change?',
      message: 'Start mould change on "$machineName" to "$newMould"?\n\nThis will stop current production.',
      confirmText: 'Start Change',
      cancelText: 'Cancel',
      icon: Icons.swap_horiz,
      confirmColor: const Color(0xFFFFD166),
    );
  }

  /// Show reset data confirmation
  static Future<bool> confirmReset({
    required BuildContext context,
    required String dataType,
  }) async {
    return await show(
      context: context,
      title: 'Reset $dataType?',
      message: 'This will permanently delete all $dataType data. This action cannot be undone!',
      confirmText: 'Reset',
      cancelText: 'Cancel',
      icon: Icons.warning_amber_rounded,
      isDangerous: true,
    );
  }

  /// Show custom action confirmation with input
  static Future<String?> showWithInput({
    required BuildContext context,
    required String title,
    required String message,
    required String inputLabel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121821),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: inputLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result;
  }
}
