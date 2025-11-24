# Security Migration Guide
## From Open Rules to Production-Ready Security

This guide walks you through migrating from the current insecure setup to a production-ready, authenticated system.

---

## Prerequisites

- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] Access to Firebase Console
- [ ] App running successfully with current setup
- [ ] Backup of current data

---

## Step-by-Step Migration

### Step 1: Enable Firebase Authentication (5 minutes)

1. **Open Firebase Console:**
   ```
   https://console.firebase.google.com/project/promould-ed22a/authentication
   ```

2. **Enable Email/Password Auth:**
   - Click **Get Started** (if first time)
   - Click **Sign-in method** tab
   - Click **Email/Password**
   - Toggle **Enable**
   - Click **Save**

3. **Verify:**
   - Should see "Email/Password" with status "Enabled"

---

### Step 2: Add Firebase Auth Dependency (2 minutes)

The dependency is already added in `pubspec.yaml`:
```yaml
firebase_auth: ^5.3.1
```

Run:
```bash
cd /workspaces/ProMould
flutter pub get
```

---

### Step 3: Initialize Firebase Auth in App (5 minutes)

**File:** `lib/main.dart`

Add import at top:
```dart
import 'services/firebase_auth_service.dart';
```

In `main()` function, after `Firebase.initializeApp()`:
```dart
// Initialize Firebase Auth
LogService.info('Initializing Firebase Auth...');
await FirebaseAuthService.initialize();
LogService.info('Firebase Auth initialized');
```

---

### Step 4: Migrate Existing Users (10 minutes)

#### Option A: Automatic Migration (Recommended)

Create a one-time migration screen or button in admin settings:

```dart
// In admin settings screen
ElevatedButton(
  onPressed: () async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Migrating Users...'),
        content: CircularProgressIndicator(),
      ),
    );
    
    await FirebaseAuthService.migrateAllUsers();
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Users migrated successfully!')),
    );
  },
  child: Text('Migrate Users to Firebase'),
)
```

#### Option B: Manual Migration

For each user in Hive:
```dart
final usersBox = Hive.box('usersBox');
for (var key in usersBox.keys) {
  final user = usersBox.get(key) as Map;
  await FirebaseAuthService.createUser(
    user['username'],
    user['password'],
    user['level'],
  );
}
```

#### Verify Migration

Check Firebase Console → Authentication → Users
- Should see all users listed
- Emails will be: `username@promould.local`

---

### Step 5: Store User Data in Firestore (10 minutes)

After creating Firebase Auth users, store their data in Firestore:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> syncUserToFirestore(String uid, Map userData) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'username': userData['username'],
    'level': userData['level'],
    'shift': userData['shift'],
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// Run for all users
final usersBox = Hive.box('usersBox');
for (var key in usersBox.keys) {
  final user = usersBox.get(key) as Map;
  final email = '${user['username']}@promould.local';
  
  // Get Firebase user
  final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
  if (methods.isNotEmpty) {
    // Sign in to get UID
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: user['password'],
    );
    
    // Store in Firestore
    await syncUserToFirestore(credential.user!.uid, user);
  }
}
```

---

### Step 6: Update Login Screen (15 minutes)

**File:** `lib/screens/login_screen.dart`

Replace the `_login()` method:

```dart
void _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final username = _u.text.trim();
    final password = _p.text;

    // Try Firebase Auth
    final credential = await FirebaseAuthService.signIn(username, password);
    
    if (credential == null) {
      throw Exception('Login failed');
    }

    // Get user data from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('User data not found');
    }

    final userData = userDoc.data()!;
    final level = (userData['level'] ?? 1) as int;

    LogService.auth('User $username logged in (Level $level)');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoleRouter(level: level, username: username),
        ),
      );
    }
  } catch (e) {
    LogService.error('Login failed', e);
    ErrorHandler.handle(e, context: 'Login');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

### Step 7: Test Authentication (15 minutes)

1. **Test Login:**
   ```bash
   flutter run
   ```
   - Try logging in with existing user
   - Should work with Firebase Auth

2. **Test Logout:**
   - Add logout button that calls:
   ```dart
   await FirebaseAuthService.signOut();
   ```

3. **Test Invalid Credentials:**
   - Try wrong password → Should fail
   - Try non-existent user → Should fail

4. **Check Logs:**
   ```bash
   flutter logs | grep "Firebase Auth"
   ```
   - Should see successful authentication

---

### Step 8: Deploy Production Rules (10 minutes)

#### Using Firebase CLI (Recommended)

```bash
cd /workspaces/ProMould

# Login to Firebase
firebase login

# Initialize project (if not done)
firebase init

# Deploy Firestore rules
firebase deploy --only firestore:rules

# When prompted, use: firestore.rules.production

# Deploy Storage rules
firebase deploy --only storage:rules

# When prompted, use: storage.rules.production
```

#### Manual Deployment

**Firestore:**
1. Open: https://console.firebase.google.com/project/promould-ed22a/firestore/rules
2. Copy entire content from `firestore.rules.production`
3. Click **Publish**
4. Wait for "Rules published successfully"

**Storage:**
1. Open: https://console.firebase.google.com/project/promould-ed22a/storage/rules
2. Copy entire content from `storage.rules.production`
3. Click **Publish**
4. Wait for "Rules published successfully"

---

### Step 9: Verify Security (20 minutes)

#### Test 1: Unauthenticated Access (Should Fail)

```bash
# Try to read data without auth
curl -X GET \
  "https://firestore.googleapis.com/v1/projects/promould-ed22a/databases/(default)/documents/machines" \
  -H "Content-Type: application/json"

# Expected: 403 Forbidden or PERMISSION_DENIED
```

#### Test 2: Authenticated Access (Should Work)

1. Login to app
2. Navigate to machines screen
3. Should load data successfully
4. Check logs for any permission errors

#### Test 3: Role-Based Access

**As Operator (Level 1):**
- ✅ Can view machines
- ✅ Can create inputs
- ❌ Cannot delete machines
- ❌ Cannot modify users

**As Admin (Level 4):**
- ✅ Can view everything
- ✅ Can modify everything
- ✅ Can delete records
- ✅ Can manage users

#### Test 4: Offline Mode

1. Turn off internet
2. App should still work with local Hive data
3. Turn on internet
4. Data should sync automatically

---

### Step 10: Update User Management (15 minutes)

Update the user creation flow to use Firebase Auth:

**File:** `lib/screens/manage_users_screen.dart`

When creating a new user:

```dart
Future<void> _createUser(String username, String password, int level) async {
  try {
    // Create in Firebase Auth
    final credential = await FirebaseAuthService.createUser(
      username,
      password,
      level,
    );

    if (credential == null) {
      throw Exception('Failed to create Firebase user');
    }

    // Store in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'username': username,
      'level': level,
      'shift': 'Day',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also store in Hive for offline access
    final usersBox = Hive.box('usersBox');
    await usersBox.put(username, {
      'username': username,
      'password': password,
      'level': level,
      'shift': 'Day',
      'uid': credential.user!.uid,
    });

    LogService.info('User created: $username');
  } catch (e) {
    LogService.error('Failed to create user', e);
    rethrow;
  }
}
```

---

## Verification Checklist

After completing all steps:

### Authentication
- [ ] Firebase Authentication enabled in console
- [ ] All users migrated to Firebase Auth
- [ ] User data stored in Firestore
- [ ] Login works with Firebase Auth
- [ ] Logout works correctly

### Security Rules
- [ ] Production Firestore rules deployed
- [ ] Production Storage rules deployed
- [ ] Unauthenticated access blocked
- [ ] Role-based access working
- [ ] Rules tested in Firebase Console

### App Functionality
- [ ] Login screen works
- [ ] Dashboard loads
- [ ] Can create/read/update/delete data (based on role)
- [ ] Offline mode works
- [ ] Data syncs when online
- [ ] No permission errors in logs

### User Management
- [ ] Can create new users (admin only)
- [ ] New users stored in Firebase Auth
- [ ] New users stored in Firestore
- [ ] User levels enforced correctly

---

## Troubleshooting

### Issue: "PERMISSION_DENIED" after deploying rules

**Cause:** User not authenticated or rules too restrictive

**Solution:**
1. Check if user is logged in: `FirebaseAuth.instance.currentUser`
2. Verify user has correct level in Firestore
3. Check rules in Firebase Console
4. Test rules in Rules Playground

### Issue: Login fails after migration

**Cause:** User not migrated or password mismatch

**Solution:**
1. Check Firebase Console → Authentication → Users
2. Verify user exists
3. Try password reset
4. Re-run migration for that user

### Issue: Offline mode broken

**Cause:** Hive data not syncing with Firestore

**Solution:**
1. Keep Hive as local cache
2. Sync Firestore → Hive on login
3. Use Hive for offline reads
4. Queue Firestore writes when offline

### Issue: Rules too restrictive

**Cause:** Production rules blocking legitimate operations

**Solution:**
1. Check user level in Firestore
2. Verify rule logic in `firestore.rules.production`
3. Test specific operation in Rules Playground
4. Adjust rules if needed

---

## Rollback Procedure

If migration fails:

### Quick Rollback (5 minutes)

```bash
# Redeploy open rules
firebase deploy --only firestore:rules --config firestore.rules
firebase deploy --only storage:rules --config storage.rules
```

### Full Rollback (15 minutes)

1. Redeploy open rules (above)
2. Revert login screen changes:
   ```bash
   git checkout HEAD~1 lib/screens/login_screen.dart
   ```
3. Remove Firebase Auth initialization from main.dart
4. Restart app

---

## Post-Migration

### Monitor for Issues

1. **Check Firebase Console:**
   - Authentication → Users (should see activity)
   - Firestore → Usage (should see reads/writes)
   - Storage → Usage (should see uploads)

2. **Check App Logs:**
   ```bash
   flutter logs | grep -E "(auth|permission|denied)"
   ```

3. **User Feedback:**
   - Monitor for login issues
   - Check for permission errors
   - Verify all features working

### Optimize Rules

After 1-2 weeks of production use:

1. Review Firebase Console → Firestore → Rules → Metrics
2. Identify frequently denied operations
3. Adjust rules if legitimate operations blocked
4. Add indexes for slow queries

---

## Timeline Summary

| Step | Time | Critical |
|------|------|----------|
| Enable Firebase Auth | 5 min | ✅ Yes |
| Add dependency | 2 min | ✅ Yes |
| Initialize in app | 5 min | ✅ Yes |
| Migrate users | 10 min | ✅ Yes |
| Sync to Firestore | 10 min | ✅ Yes |
| Update login | 15 min | ✅ Yes |
| Test auth | 15 min | ✅ Yes |
| Deploy rules | 10 min | ✅ Yes |
| Verify security | 20 min | ✅ Yes |
| Update user mgmt | 15 min | ⚠️ Optional |

**Total: ~2 hours (critical path)**

---

## Support

If you encounter issues:

1. Check `SECURITY_CRITICAL.md` for warnings
2. Review Firebase Console error logs
3. Test rules in Rules Playground
4. Check app logs: `flutter logs`
5. Verify user exists in Firebase Auth

---

**Status:** Ready for migration  
**Estimated Time:** 2-4 hours  
**Difficulty:** Intermediate  
**Risk:** Low (rollback available)
