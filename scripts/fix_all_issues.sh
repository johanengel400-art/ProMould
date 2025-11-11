#!/bin/bash
# Automatically fix common code quality issues

set -e

echo "🔧 Fixing code quality issues..."
echo ""

# 1. Format all code
echo "📝 Formatting code..."
dart format lib/ test/
echo "✅ Code formatted"
echo ""

# 2. Remove unused imports (requires dart fix)
echo "🧹 Removing unused imports..."
dart fix --apply
echo "✅ Unused imports removed"
echo ""

# 3. Run analyzer to see remaining issues
echo "🔬 Running analyzer..."
flutter analyze --no-fatal-infos --no-fatal-warnings

echo ""
echo "✅ Automatic fixes applied!"
echo "   Review the changes and commit if everything looks good."
