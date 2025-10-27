# Manual Steps Required

## Overview
This document outlines the manual steps needed to complete the ProMould v7.2 setup after the code fixes have been applied.

## Critical Steps (Must Do)

### 1. Install Dependencies
**Why**: The `syncfusion_flutter_gauges` package was added to `pubspec.yaml` but not yet installed.

**Command**:
```bash
cd /workspaces/promould_v7_2
flutter pub get
```

**Expected Output**:
```
Running "flutter pub get" in promould_v7_2...
Resolving dependencies...
+ syncfusion_flutter_gauges 26.1.41
Changed X dependencies!
```

### 2. Verify Code Quality
**Why**: Ensure all Flutter analysis errors are resolved.

**Command**:
```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
```

**Expected Output**:
```
Analyzing promould_v7_2...
No issues found!
```

**If Issues Found**:
- Review the error messages
- Most common issues:
  - Unused imports (can be auto-removed by IDE)
  - Unnecessary null assertions
  - Type mismatches
- Refer to `FIXES_APPLIED.md` for patterns

### 3. Test Compilation
**Why**: Ensure the app builds without errors.

**Command**:
```bash
flutter build apk --debug
# or for iOS:
flutter build ios --debug
```

**Expected Output**:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

## Recommended Steps

### 4. Run the App
**Why**: Verify all features work as expected.

**Command**:
```bash
flutter run
# or for specific device:
flutter run -d <device_id>
```

**What to Test**:
- See `TESTING_GUIDE.md` for comprehensive testing checklist
- Focus on:
  - Live progress updates
  - Scrap rate displays
  - New dashboard design
  - Timeline card layout
  - Mould change scheduler
  - Quality control features

### 5. Check Background Services
**Why**: Ensure services start correctly and run continuously.

**What to Verify**:
1. Live Progress Service starts on app launch
2. Notification Service starts on app launch
3. Shot counts update every 5 seconds
4. Notifications refresh every 30 seconds

**How to Check**:
- Look for console logs:
  ```
  ⏱️ Starting live progress service...
  ✅ Live progress service started
  🔔 Starting notification service...
  ✅ Notification service started
  ```

### 6. Test Firebase Sync
**Why**: Ensure data syncs correctly with Firebase.

**What to Test**:
1. Make changes in the app
2. Check Firebase Console for updates
3. Verify changes appear on other devices
4. Test offline mode and sync on reconnect

### 7. Performance Testing
**Why**: Ensure app performs well with real data.

**What to Test**:
1. Add multiple machines and jobs
2. Navigate between screens
3. Check memory usage
4. Monitor for lag or stuttering

## Optional Steps

### 8. Code Cleanup (IDE)
**Why**: Remove any remaining unused imports or variables.

**How**:
- In VS Code: Right-click → "Organize Imports"
- In Android Studio: Code → Optimize Imports
- Run: `dart fix --apply`

### 9. Format Code
**Why**: Ensure consistent code style.

**Command**:
```bash
flutter format lib/
```

### 10. Update Documentation
**Why**: Keep documentation in sync with code changes.

**Files to Review**:
- `README.md` - Update version number and features list
- `CHANGELOG.md` - Add entry for v7.2
- `FEATURES_V8.md` - Already updated with all features

## Troubleshooting

### Issue: "flutter: command not found"
**Solution**: Ensure Flutter is installed and in PATH
```bash
export PATH="$PATH:/path/to/flutter/bin"
# or add to ~/.bashrc or ~/.zshrc
```

### Issue: "Target of URI doesn't exist: package:syncfusion_flutter_gauges"
**Solution**: Run `flutter pub get` to install dependencies

### Issue: Build fails with "Gradle error"
**Solution**: 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Issue: "Hive box not found"
**Solution**: Ensure all boxes are opened in `main.dart`:
- usersBox
- floorsBox
- machinesBox
- jobsBox
- mouldsBox
- issuesBox
- inputsBox
- queueBox
- downtimeBox
- checklistsBox
- mouldChangesBox
- qualityInspectionsBox
- qualityHoldsBox

### Issue: Live progress not updating
**Solution**: 
1. Check if service started (look for console log)
2. Verify job has `startTime` and `cycleTime`
3. Check job status is 'Running'
4. Restart app to reinitialize service

### Issue: Scrap rates showing 0%
**Solution**:
1. Ensure `inputsBox` has data
2. Check inputs have `shots` and `scrap` fields
3. Verify machine IDs match between inputs and machines

## Next Steps After Manual Steps

1. ✅ Commit the working code
2. ✅ Push to repository
3. ✅ Create release tag (v7.2)
4. ✅ Deploy to production
5. ✅ Monitor for issues
6. ✅ Gather user feedback

## Support

If you encounter issues not covered here:
1. Check Flutter logs: `flutter logs`
2. Review Firebase Console for sync errors
3. Check Hive database: `Hive.box('boxName').values`
4. Enable debug mode for more verbose logging

## Summary

**Minimum Required Steps**:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run`

**Time Estimate**: 5-10 minutes

**Difficulty**: Easy (assuming Flutter environment is set up)

---

**Last Updated**: 2025-10-27
**Version**: 7.2
**Status**: Ready for manual execution
