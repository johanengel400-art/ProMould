import 'package:hive/hive.dart';
import '../services/log_service.dart';

/// Utility to initialize or reset app data
class DataInitializer {
  /// Create default admin user if none exists
  static Future<void> ensureAdminExists() async {
    try {
      final usersBox = Hive.box('usersBox');
      
      if (usersBox.isEmpty) {
        LogService.info('No users found, creating default admin...');
        await createDefaultAdmin();
        return;
      }

      // Check if admin exists
      bool adminExists = false;
      for (var key in usersBox.keys) {
        final user = usersBox.get(key) as Map?;
        if (user != null && user['username'] == 'admin') {
          adminExists = true;
          break;
        }
      }

      if (!adminExists) {
        LogService.warning('Admin user not found, creating...');
        await createDefaultAdmin();
      } else {
        LogService.info('Admin user exists');
      }
    } catch (e) {
      LogService.error('Error ensuring admin exists', e);
    }
  }

  /// Create default admin user
  static Future<void> createDefaultAdmin() async {
    try {
      final usersBox = Hive.box('usersBox');
      final adminUser = {
        'username': 'admin',
        'password': 'admin123',
        'level': 4,
        'shift': 'Any',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await usersBox.put('admin', adminUser);
      LogService.auth('Default admin user created successfully');
    } catch (e) {
      LogService.error('Failed to create default admin', e);
      rethrow;
    }
  }

  /// Create sample users for testing
  static Future<void> createSampleUsers() async {
    try {
      final usersBox = Hive.box('usersBox');
      
      final users = [
        {
          'username': 'admin',
          'password': 'admin123',
          'level': 4,
          'shift': 'Any',
        },
        {
          'username': 'manager',
          'password': 'manager123',
          'level': 3,
          'shift': 'Day',
        },
        {
          'username': 'supervisor',
          'password': 'super123',
          'level': 2,
          'shift': 'Day',
        },
        {
          'username': 'operator',
          'password': 'operator123',
          'level': 1,
          'shift': 'Day',
        },
      ];

      for (var user in users) {
        await usersBox.put(user['username'], user);
        LogService.info('Created user: ${user['username']}');
      }

      LogService.info('Sample users created successfully');
    } catch (e) {
      LogService.error('Failed to create sample users', e);
    }
  }

  /// Get all users (for debugging)
  static List<Map<String, dynamic>> getAllUsers() {
    try {
      final usersBox = Hive.box('usersBox');
      final users = <Map<String, dynamic>>[];
      
      for (var key in usersBox.keys) {
        final user = usersBox.get(key) as Map?;
        if (user != null) {
          users.add(Map<String, dynamic>.from(user));
        }
      }
      
      return users;
    } catch (e) {
      LogService.error('Error getting all users', e);
      return [];
    }
  }

  /// Clear all user data (use with caution!)
  static Future<void> clearAllUsers() async {
    try {
      final usersBox = Hive.box('usersBox');
      await usersBox.clear();
      LogService.warning('All users cleared');
    } catch (e) {
      LogService.error('Error clearing users', e);
    }
  }

  /// Reset to default state
  static Future<void> resetToDefaults() async {
    try {
      LogService.warning('Resetting to default state...');
      await clearAllUsers();
      await createDefaultAdmin();
      LogService.info('Reset complete');
    } catch (e) {
      LogService.error('Error resetting to defaults', e);
    }
  }
}
