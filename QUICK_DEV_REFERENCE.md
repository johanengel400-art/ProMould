# Quick Development Reference

## 🚀 Before Every Commit

```bash
./scripts/quality_check.sh
```

## 🔧 Common Commands

```bash
# Format code
flutter format lib/ test/

# Analyze code
flutter analyze --fatal-infos --fatal-warnings

# Auto-fix issues
./scripts/fix_all_issues.sh

# Run tests
flutter test

# Build APK
flutter build apk --release
```

## ✅ Pre-Commit Checklist

- [ ] Code formatted
- [ ] No analyzer errors
- [ ] No unused imports
- [ ] No print() statements
- [ ] Const constructors used
- [ ] Tests pass

## 🚫 Never Do

- ❌ `git commit --no-verify` (skips checks)
- ❌ `print()` in production code (use LogService)
- ❌ Push without running quality check
- ❌ Ignore analyzer warnings
- ❌ Leave unused imports

## ✅ Always Do

- ✅ Run `./scripts/quality_check.sh` before pushing
- ✅ Use `const` constructors
- ✅ Remove unused imports
- ✅ Use `LogService` for logging
- ✅ Check `mounted` before setState
- ✅ Dispose controllers

## 🐛 Quick Fixes

### Unused Import
```dart
// Remove the import line
```

### Print Statement
```dart
// Before
print('message');

// After
LogService.info('message');
```

### Missing Const
```dart
// Before
SizedBox(height: 16)

// After
const SizedBox(height: 16)
```

### Undefined Identifier
```dart
// Before
final status = job['status'];

// After
final status = widget.job['status'];
```

### Nullable Variable
```dart
// Before
Duration interval;

// After
Duration? interval;
```

## 📞 Help

See `DEVELOPMENT_BEST_PRACTICES.md` for detailed guide.
