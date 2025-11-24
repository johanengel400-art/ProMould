# Firebase Access Fix Guide

## Problem
App not opening - likely due to Firebase security rules blocking access.

## Solution

### Option 1: Deploy Security Rules (Recommended)

1. **Install Firebase CLI** (if not already installed):
```bash
npm install -g firebase-tools
```

2. **Login to Firebase**:
```bash
firebase login
```

3. **Initialize Firebase in project** (if not done):
```bash
cd /workspaces/ProMould
firebase init
```
Select:
- Firestore
- Storage
- Use existing project: `promould-ed22a`

4. **Deploy the rules**:
```bash
firebase deploy --only firestore:rules,storage:rules
```

### Option 2: Manual Setup via Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/project/promould-ed22a

2. **Update Firestore Rules**:
   - Navigate to: Firestore Database → Rules
   - Replace with:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
   - Click "Publish"

3. **Update Storage Rules**:
   - Navigate to: Storage → Rules
   - Replace with:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if true;
       }
     }
   }
   ```
   - Click "Publish"

### Option 3: Check Current Rules

1. Go to Firebase Console
2. Check Firestore Rules - if they say `allow read, write: if false;` that's the problem
3. Change to `allow read, write: if true;` for development

## Verification

After deploying rules, test the app:

1. **Clear app data** (if previously installed):
```bash
adb shell pm clear com.promould.app
```

2. **Reinstall and run**:
```bash
flutter clean
flutter pub get
flutter run
```

3. **Check logs**:
```bash
flutter logs
```

Look for:
- ✅ "Firebase initialized successfully"
- ✅ "Sync services started successfully"
- ❌ "PERMISSION_DENIED" errors

## Enhanced Error Handling

The app now has improved error handling:
- Firebase failures won't crash the app
- App can run in offline mode if Firebase is unavailable
- Error screen shows specific issues

## Security Note

⚠️ **IMPORTANT**: The current rules allow unrestricted access (development mode).

**Before production**, implement proper authentication:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can access
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Then implement Firebase Authentication in the app:
1. Enable Email/Password auth in Firebase Console
2. Update login screen to use Firebase Auth
3. Store user tokens securely

## Common Issues

### Issue 1: "Firebase initialization failed"
**Cause**: Invalid API keys or project configuration
**Fix**: 
- Verify `google-services.json` matches Firebase Console
- Check `firebase_options.dart` has correct credentials
- Regenerate config files if needed

### Issue 2: "PERMISSION_DENIED"
**Cause**: Firestore/Storage rules blocking access
**Fix**: Deploy the open rules above (development only)

### Issue 3: "Network error"
**Cause**: No internet connection or Firebase services down
**Fix**: 
- Check internet connection
- App will work offline with local Hive storage
- Sync will resume when connection restored

### Issue 4: App crashes on startup
**Cause**: Critical initialization failure
**Fix**: 
- Check logs: `flutter logs`
- Look for stack trace in error screen
- Verify all dependencies installed: `flutter pub get`

## Testing Checklist

- [ ] Firebase Console shows project exists
- [ ] Firestore rules allow access
- [ ] Storage rules allow access
- [ ] `google-services.json` is present
- [ ] App package name matches: `com.promould.app`
- [ ] Internet connection available
- [ ] App permissions granted (storage, camera, etc.)

## Support

If issues persist:
1. Check Firebase Console → Usage for any quota limits
2. Verify billing is enabled (if using paid features)
3. Check Firebase Status: https://status.firebase.google.com/
4. Review app logs for specific error messages
