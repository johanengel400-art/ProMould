# Firebase Auth Service

## Status: Disabled

The `firebase_auth_service.dart` file has been renamed to `firebase_auth_service.dart.disabled` to prevent build errors.

## Why Disabled

The service requires the `firebase_auth` package which is currently commented out in `pubspec.yaml` to allow builds to pass.

## To Enable

When ready to use Firebase Authentication:

1. **Uncomment firebase_auth in pubspec.yaml:**
   ```yaml
   firebase_auth: ^5.3.1
   ```

2. **Rename the service file:**
   ```bash
   mv lib/services/firebase_auth_service.dart.disabled lib/services/firebase_auth_service.dart
   ```

3. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Follow migration guide:**
   See `SECURITY_MIGRATION_GUIDE.md` for complete setup instructions.

## What It Provides

Once enabled, the Firebase Auth Service provides:

- Email/password authentication
- Automatic user migration from Hive
- Password management (reset, update)
- User creation and deletion
- Seamless integration with existing code

## Current Authentication

The app currently uses Hive-based authentication which works fine for development and testing. Firebase Auth is only needed for production security with the production security rules.

## Documentation

- `SECURITY_CRITICAL.md` - Security overview
- `SECURITY_MIGRATION_GUIDE.md` - Step-by-step migration
- `BUILD_FIX.md` - Build troubleshooting
- `README_SECURITY.md` - Quick reference
