import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'log_service.dart';

/// Firebase Authentication service for production use
/// 
/// This service integrates Firebase Auth with the existing Hive-based
/// user system. It creates Firebase users from Hive users and manages
/// authentication state.
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static User? _currentUser;

  /// Initialize Firebase Auth and set up listeners
  static Future<void> initialize() async {
    try {
      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        _currentUser = user;
        if (user != null) {
          LogService.auth('User authenticated: ${user.email}');
        } else {
          LogService.auth('User signed out');
        }
      });

      LogService.info('Firebase Auth initialized');
    } catch (e) {
      LogService.error('Failed to initialize Firebase Auth', e);
    }
  }

  /// Get current authenticated user
  static User? get currentUser => _currentUser ?? _auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  /// 
  /// For migration: uses username as email (username@promould.local)
  static Future<UserCredential?> signIn(String username, String password) async {
    try {
      final email = _usernameToEmail(username);
      LogService.debug('Attempting Firebase sign in: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      LogService.auth('Firebase sign in successful: $email');
      return credential;
    } on FirebaseAuthException catch (e) {
      LogService.warning('Firebase sign in failed: ${e.code}');
      
      // If user doesn't exist in Firebase, try to migrate from Hive
      if (e.code == 'user-not-found') {
        LogService.info('User not in Firebase, attempting migration...');
        return await _migrateAndSignIn(username, password);
      }
      
      rethrow;
    } catch (e) {
      LogService.error('Unexpected error during sign in', e);
      return null;
    }
  }

  /// Create a new Firebase user
  static Future<UserCredential?> createUser(
    String username,
    String password,
    int level,
  ) async {
    try {
      final email = _usernameToEmail(username);
      LogService.debug('Creating Firebase user: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name with username
      await credential.user?.updateDisplayName(username);

      LogService.auth('Firebase user created: $email (Level $level)');
      return credential;
    } on FirebaseAuthException catch (e) {
      LogService.error('Failed to create Firebase user: ${e.code}', e);
      return null;
    }
  }

  /// Migrate existing Hive user to Firebase
  static Future<UserCredential?> _migrateAndSignIn(
    String username,
    String password,
  ) async {
    try {
      // Check if user exists in Hive
      final usersBox = Hive.box('usersBox');
      Map? hiveUser;

      if (usersBox.containsKey(username)) {
        hiveUser = usersBox.get(username) as Map?;
      } else {
        hiveUser = usersBox.values
            .cast<Map>()
            .firstWhere(
              (u) => u['username'] == username,
              orElse: () => {},
            );
      }

      if (hiveUser == null || hiveUser.isEmpty) {
        LogService.warning('User not found in Hive: $username');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found in local database',
        );
      }

      // Verify password matches Hive
      if (hiveUser['password'] != password) {
        LogService.warning('Password mismatch during migration: $username');
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Invalid password',
        );
      }

      // Create Firebase user
      final level = (hiveUser['level'] ?? 1) as int;
      final credential = await createUser(username, password, level);

      if (credential != null) {
        LogService.auth('User migrated successfully: $username');
        return credential;
      }

      return null;
    } catch (e) {
      LogService.error('Migration failed for user: $username', e);
      rethrow;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      LogService.auth('User signed out');
    } catch (e) {
      LogService.error('Sign out failed', e);
    }
  }

  /// Reset password (send email)
  static Future<void> sendPasswordResetEmail(String username) async {
    try {
      final email = _usernameToEmail(username);
      await _auth.sendPasswordResetEmail(email: email);
      LogService.info('Password reset email sent to: $email');
    } catch (e) {
      LogService.error('Failed to send password reset email', e);
      rethrow;
    }
  }

  /// Update user password
  static Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.updatePassword(newPassword);
      LogService.auth('Password updated for user: ${user.email}');
    } catch (e) {
      LogService.error('Failed to update password', e);
      rethrow;
    }
  }

  /// Delete user account
  static Future<void> deleteUser() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.delete();
      LogService.auth('User deleted: ${user.email}');
    } catch (e) {
      LogService.error('Failed to delete user', e);
      rethrow;
    }
  }

  /// Convert username to email format for Firebase
  /// Example: "admin" -> "admin@promould.local"
  static String _usernameToEmail(String username) {
    return '$username@promould.local';
  }

  /// Extract username from Firebase email
  /// Example: "admin@promould.local" -> "admin"
  static String emailToUsername(String email) {
    return email.split('@').first;
  }

  /// Migrate all Hive users to Firebase (one-time operation)
  static Future<void> migrateAllUsers() async {
    try {
      LogService.info('Starting bulk user migration...');
      final usersBox = Hive.box('usersBox');
      int migrated = 0;
      int failed = 0;

      for (var key in usersBox.keys) {
        final user = usersBox.get(key) as Map?;
        if (user == null) continue;

        final username = user['username'] as String?;
        final password = user['password'] as String?;
        final level = (user['level'] ?? 1) as int;

        if (username == null || password == null) {
          LogService.warning('Skipping invalid user: $key');
          failed++;
          continue;
        }

        try {
          await createUser(username, password, level);
          migrated++;
          LogService.info('Migrated user: $username');
        } catch (e) {
          LogService.warning('Failed to migrate user: $username - $e');
          failed++;
        }
      }

      LogService.info('Migration complete: $migrated migrated, $failed failed');
    } catch (e) {
      LogService.error('Bulk migration failed', e);
    }
  }
}
