// Access Control Wrapper
// Prevents unauthorized access to screens based on user level

import 'package:flutter/material.dart';

class AccessControlWrapper extends StatelessWidget {
  final int userLevel;
  final int requiredLevel;
  final Widget child;
  final String? deniedMessage;

  const AccessControlWrapper({
    super.key,
    required this.userLevel,
    required this.requiredLevel,
    required this.child,
    this.deniedMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (userLevel >= requiredLevel) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Access Denied',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                deniedMessage ?? 'You do not have permission to access this page.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CC9F0),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to check access
bool hasAccess(int userLevel, int requiredLevel) {
  return userLevel >= requiredLevel;
}

// User level constants
class UserLevel {
  static const int operator = 1;
  static const int setter = 2;
  static const int manager = 3;
  static const int admin = 4;
}
