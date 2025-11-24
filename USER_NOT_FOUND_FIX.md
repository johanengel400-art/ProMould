# User Not Found - Fix Guide

## Problem
Getting "User not found" error when trying to login.

## Quick Fix

### Option 1: Use Debug Button (Easiest)
1. Open the app
2. On login screen, click **"Show Debug Info"** button
3. If no users shown, click **"Create Admin User"**
4. Login with: `admin` / `admin123`

### Option 2: Clear App Data
```bash
# Clear app data and reinstall
adb shell pm clear com.promould.app
flutter run
```

This will recreate the default admin user automatically.

### Option 3: Manual User Creation
If app is running but users are missing:

1. Click "Show Debug Info" on login screen
2. Click "Create Admin User" button
3. Try logging in again

## Default Credentials

```
Username: admin
Password: admin123
Level: 4 (Admin)
```

## What Was Fixed

### 1. Enhanced User Initialization
- Added `DataInitializer` utility class
- Automatic admin creation on first run
- Better error handling and logging

### 2. Improved Login Screen
- Added debug info button
- Shows available users
- Can create admin user on demand
- Better error messages

### 3. Better Logging
- Logs user count on startup
- Shows available usernames
- Tracks login attempts

## Troubleshooting

### Issue: "User not found" even after creating admin
**Cause:** User data not persisting or wrong username

**Solution:**
1. Click "Show Debug Info" to see actual usernames
2. Make sure you're typing exactly: `admin` (lowercase)
3. Check logs for user creation confirmation

### Issue: Debug button doesn't show users
**Cause:** Hive box not initialized properly

**Solution:**
```bash
# Completely reset app
adb shell pm clear com.promould.app
adb uninstall com.promould.app
flutter clean
flutter pub get
flutter run
```

### Issue: Can create user but still can't login
**Cause:** Login logic not finding user correctly

**Solution:**
1. Check logs: `flutter logs`
2. Look for: "Login attempt for user: admin"
3. Should see: "Found user by key: admin"
4. If not, user key doesn't match username

## Testing Checklist

After fix:
- [ ] App opens successfully
- [ ] Login screen shows
- [ ] "Show Debug Info" button visible
- [ ] Debug info shows at least 1 user (admin)
- [ ] Can login with admin/admin123
- [ ] Dashboard loads after login

## Creating Additional Users

### Via Debug Info (Development)
1. Login as admin
2. Go to Settings → Manage Users
3. Add new users

### Via Code (For Testing)
```dart
import 'package:hive/hive.dart';

// In your code
final usersBox = Hive.box('usersBox');
await usersBox.put('testuser', {
  'username': 'testuser',
  'password': 'test123',
  'level': 2,
  'shift': 'Day',
});
```

### Using DataInitializer
```dart
import 'utils/data_initializer.dart';

// Create sample users for testing
await DataInitializer.createSampleUsers();

// This creates:
// - admin / admin123 (Level 4)
// - manager / manager123 (Level 3)
// - supervisor / super123 (Level 2)
// - operator / operator123 (Level 1)
```

## Understanding User Levels

| Level | Role | Access |
|-------|------|--------|
| 4 | Admin | Full access, manage users, settings |
| 3 | Manager | View all, manage jobs, quality control |
| 2 | Supervisor | View assigned machines, input data |
| 1 | Operator | Basic input, view own tasks |

## Logs to Check

When debugging login issues, look for these in logs:

```
✅ Good logs:
- "Ensuring admin user exists..."
- "Default admin user created successfully"
- "Users box has 1 users"
- "Login attempt for user: admin"
- "Found user by key: admin"
- "User admin logged in successfully (Level 4)"

❌ Problem logs:
- "No users found!"
- "User not found: admin"
- "Users box has 0 users"
- "Error checking users"
```

## Advanced: Reset Everything

If nothing works, nuclear option:

```bash
# Stop app
adb shell am force-stop com.promould.app

# Clear all app data
adb shell pm clear com.promould.app

# Clear Hive data manually
adb shell
cd /data/data/com.promould.app/app_flutter
rm -rf *.hive *.lock
exit

# Reinstall
flutter clean
flutter pub get
flutter run
```

## Code Changes Made

### main.dart
- Added `DataInitializer.ensureAdminExists()`
- Better logging of user initialization
- Automatic admin creation

### login_screen.dart
- Added `_checkUsers()` on init
- Enhanced login logic with better error handling
- Added "Show Debug Info" button
- Can create admin user from UI

### data_initializer.dart (NEW)
- `ensureAdminExists()` - Checks and creates admin
- `createDefaultAdmin()` - Creates admin user
- `createSampleUsers()` - Creates test users
- `getAllUsers()` - Lists all users
- `resetToDefaults()` - Clears and recreates admin

## Prevention

To avoid this issue in future:

1. **Always check logs** after app installation
2. **Verify user creation** in startup logs
3. **Test login** immediately after deployment
4. **Keep backup** of user data before updates

## Support

If issue persists:
1. Run: `flutter logs > app_logs.txt`
2. Try to login
3. Check app_logs.txt for errors
4. Look for "User not found" or "Error checking users"
5. Share relevant log lines for debugging

---

**Status:** ✅ Fixed in latest commit  
**Default User:** admin / admin123  
**Debug Tool:** "Show Debug Info" button on login screen
