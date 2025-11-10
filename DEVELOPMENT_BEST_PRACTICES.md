# ProMould Development Best Practices

## 🎯 Goal: Zero Build Failures

This guide ensures all code passes CI/CD checks **before** pushing to GitHub.

---

## 🚀 Quick Start

### Initial Setup (One Time)

```bash
# 1. Setup Git hooks
./scripts/setup_hooks.sh

# 2. Verify setup
git config core.hooksPath
# Should output: .githooks
```

### Before Every Commit

The pre-commit hook will automatically run, but you can also run manually:

```bash
# Run all quality checks
./scripts/quality_check.sh

# Or just analyze
flutter analyze --fatal-infos --fatal-warnings

# Or just format
flutter format lib/ test/
```

---

## 📋 Code Quality Checklist

Before committing, ensure:

- [ ] ✅ Code is formatted (`flutter format lib/ test/`)
- [ ] ✅ No analyzer errors (`flutter analyze`)
- [ ] ✅ No unused imports
- [ ] ✅ All variables properly typed
- [ ] ✅ No print() statements (use LogService)
- [ ] ✅ Const constructors where possible
- [ ] ✅ Proper null safety
- [ ] ✅ No TODO comments (create issues instead)

---

## 🛠️ Available Tools

### 1. Quality Check Script
**Purpose:** Comprehensive check before pushing

```bash
./scripts/quality_check.sh
```

**Checks:**
- Flutter installation
- Dependencies
- Code formatting
- Code analysis
- Unused files
- Common issues (print, TODO, etc.)
- Tests

### 2. Auto-Fix Script
**Purpose:** Automatically fix common issues

```bash
./scripts/fix_all_issues.sh
```

**Fixes:**
- Code formatting
- Unused imports
- Some linter issues

### 3. Pre-Commit Hook
**Purpose:** Automatic checks before each commit

**Location:** `.githooks/pre-commit`

**Runs automatically on:** `git commit`

**Skip (not recommended):** `git commit --no-verify`

---

## 🔍 Understanding Analyzer Errors

### Critical Errors (Must Fix)

#### `unused_import`
```dart
// ❌ Bad
import 'package:flutter/material.dart';
import '../utils/job_status.dart'; // Not used

// ✅ Good
import 'package:flutter/material.dart';
```

#### `undefined_identifier`
```dart
// ❌ Bad
final status = job['status']; // 'job' not defined

// ✅ Good
final status = widget.job['status'];
```

#### `not_assigned_potentially_non_nullable_local_variable`
```dart
// ❌ Bad
String? level;
Duration interval; // Not initialized
if (condition) {
  interval = Duration(minutes: 10);
}
// interval might not be assigned

// ✅ Good
String? level;
Duration? interval; // Nullable
if (condition) {
  interval = Duration(minutes: 10);
}
if (interval != null) {
  // Use interval
}
```

### Warnings (Should Fix)

#### `avoid_print`
```dart
// ❌ Bad
print('Debug message');

// ✅ Good
LogService.info('Debug message');

// ✅ Acceptable in tests
// ignore: avoid_print
print('Test output');
```

#### `use_build_context_synchronously`
```dart
// ❌ Bad
await someAsyncOperation();
Navigator.push(context, ...); // Context might be invalid

// ✅ Good
await someAsyncOperation();
if (mounted) {
  Navigator.push(context, ...);
}
```

### Infos (Best Practice)

#### `prefer_const_constructors`
```dart
// ❌ Not optimal
return SizedBox(height: 16);

// ✅ Better (performance)
return const SizedBox(height: 16);
```

#### `prefer_const_literals_to_create_immutables`
```dart
// ❌ Not optimal
children: [
  Text('Hello'),
  Text('World'),
]

// ✅ Better
children: const [
  Text('Hello'),
  Text('World'),
]
```

---

## 📝 Code Style Guidelines

### 1. Imports

**Order:**
1. Dart imports
2. Flutter imports
3. Package imports
4. Relative imports

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../services/sync_service.dart';
import '../utils/job_status.dart';
```

### 2. Naming Conventions

```dart
// Classes: PascalCase
class JobStatusBadge extends StatelessWidget {}

// Variables/Functions: camelCase
final overrunJobs = 5;
void calculateOverrun() {}

// Constants: lowerCamelCase with const
const primaryColor = Color(0xFF4CC9F0);

// Private: prefix with _
final _privateVariable = 'value';
void _privateMethod() {}
```

### 3. Type Annotations

```dart
// ✅ Always annotate public APIs
String getJobStatus(Map job) {
  return job['status'] as String;
}

// ✅ Can omit for obvious local variables
final count = jobs.length; // Type is obvious

// ❌ Don't omit when not obvious
final data = processData(); // What type is this?

// ✅ Better
final Map<String, dynamic> data = processData();
```

### 4. Null Safety

```dart
// ✅ Use null-aware operators
final status = job['status'] as String?;
final displayStatus = status ?? 'Unknown';

// ✅ Use null checks
if (status != null) {
  print(status.toUpperCase());
}

// ✅ Use late for guaranteed initialization
late final Box jobsBox;

@override
void initState() {
  super.initState();
  jobsBox = Hive.box('jobsBox');
}
```

### 5. Const Constructors

```dart
// ✅ Use const for immutable widgets
const SizedBox(height: 16)
const Text('Hello')
const Icon(Icons.check)

// ✅ Use const for lists/maps when possible
const ['Running', 'Overrunning', 'Finished']
const {'key': 'value'}

// ❌ Can't use const with dynamic values
Text('Count: $count') // count is variable
```

---

## 🚫 Common Mistakes to Avoid

### 1. Forgetting to Check Mounted

```dart
// ❌ Bad
Future<void> loadData() async {
  await fetchData();
  setState(() {}); // Widget might be disposed
}

// ✅ Good
Future<void> loadData() async {
  await fetchData();
  if (mounted) {
    setState(() {});
  }
}
```

### 2. Using Print in Production

```dart
// ❌ Bad
print('Job started: $jobId');

// ✅ Good
LogService.info('Job started: $jobId');
```

### 3. Not Disposing Controllers

```dart
// ❌ Bad
class MyWidget extends StatefulWidget {
  final controller = TextEditingController();
}

// ✅ Good
class MyWidget extends StatefulWidget {
  late final TextEditingController controller;
  
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### 4. Unused Imports

```dart
// ❌ Bad
import 'package:flutter/material.dart';
import '../utils/job_status.dart'; // Not used in file

// ✅ Good - Remove unused imports
import 'package:flutter/material.dart';
```

### 5. Type Mismatches

```dart
// ❌ Bad
final count = jobs.fold(0, (sum, j) => ...); // 'sum' shadows type

// ✅ Good
final count = jobs.fold<int>(0, (total, j) => ...);
```

---

## 🔄 Workflow

### Daily Development

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Make changes
# ... code ...

# 4. Run quality check
./scripts/quality_check.sh

# 5. Commit (pre-commit hook runs automatically)
git add .
git commit -m "feat: add new feature"

# 6. Push
git push origin feature/my-feature
```

### Before Creating PR

```bash
# 1. Ensure all checks pass
./scripts/quality_check.sh

# 2. Run tests
flutter test

# 3. Build to verify
flutter build apk --debug

# 4. Create PR
gh pr create --title "feat: my feature" --body "Description"
```

---

## 🐛 Troubleshooting

### "Flutter command not found"

```bash
# Check if Flutter is in PATH
which flutter

# If not, add to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or install Flutter
# See: https://flutter.dev/docs/get-started/install
```

### "Analysis failed with errors"

```bash
# 1. See what's wrong
flutter analyze

# 2. Try auto-fix
./scripts/fix_all_issues.sh

# 3. Fix remaining issues manually
# Follow error messages
```

### "Pre-commit hook not running"

```bash
# 1. Check hooks path
git config core.hooksPath

# 2. If not set, run setup
./scripts/setup_hooks.sh

# 3. Verify hook is executable
ls -la .githooks/pre-commit
# Should show: -rwxr-xr-x

# 4. If not executable
chmod +x .githooks/pre-commit
```

### "Build failed in CI but works locally"

This usually means:
1. You skipped pre-commit checks (`--no-verify`)
2. You didn't run quality check before pushing
3. Different Flutter version

**Solution:**
```bash
# Always run before pushing
./scripts/quality_check.sh

# Never skip hooks
# Don't use: git commit --no-verify
```

---

## 📊 CI/CD Pipeline

### What Runs on Push

1. **Checkout code**
2. **Setup Java & Flutter**
3. **Get dependencies**
4. **Run build_runner**
5. **Check formatting** ← Strict
6. **Analyze code** ← Strict (--fatal-infos --fatal-warnings)
7. **Build APK**
8. **Upload artifact**
9. **Create release** (on main branch)

### How to Ensure CI Passes

```bash
# Run the same checks locally
./scripts/quality_check.sh

# This checks:
# - Flutter installation
# - Dependencies
# - Formatting
# - Analysis
# - Unused files
# - Common issues
# - Tests
```

---

## 🎓 Learning Resources

### Flutter Best Practices
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)

### Linting
- [Dart Lints](https://dart.dev/tools/linter-rules)
- [Flutter Lints Package](https://pub.dev/packages/flutter_lints)

### Testing
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget/introduction)

---

## 📞 Getting Help

### Issue with Code Quality

1. Run quality check: `./scripts/quality_check.sh`
2. Read error messages carefully
3. Check this guide for solutions
4. Search error message online
5. Ask team for help

### Issue with Git Hooks

1. Verify setup: `git config core.hooksPath`
2. Re-run setup: `./scripts/setup_hooks.sh`
3. Check permissions: `ls -la .githooks/`
4. Test manually: `./.githooks/pre-commit`

---

## ✅ Success Metrics

**Goal:** Zero build failures in CI/CD

**How to achieve:**
1. ✅ Always run quality check before pushing
2. ✅ Never skip pre-commit hooks
3. ✅ Fix all analyzer issues immediately
4. ✅ Use const constructors
5. ✅ Remove unused imports
6. ✅ Use LogService instead of print
7. ✅ Follow code style guidelines

**Current Status:**
- Run `./scripts/quality_check.sh` to see current status
- All checks should pass before pushing

---

## 🔄 Continuous Improvement

This guide will be updated as we:
- Add new tools
- Discover new patterns
- Improve processes
- Learn from mistakes

**Last Updated:** November 10, 2024  
**Version:** 1.0.0

---

**Remember:** Quality code is not an accident - it's a habit! 🚀
