#!/bin/bash
# Comprehensive code quality check for ProMould
# Run this before pushing to ensure CI/CD will pass

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ProMould Code Quality Check         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

FAILED=0

# 1. Check Flutter installation
echo -e "${BLUE}[1/7]${NC} Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found${NC}"
    echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -1)${NC}"
echo ""

# 2. Get dependencies
echo -e "${BLUE}[2/7]${NC} Getting dependencies..."
if flutter pub get > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Dependencies updated${NC}"
else
    echo -e "${RED}❌ Failed to get dependencies${NC}"
    FAILED=1
fi
echo ""

# 3. Format check
echo -e "${BLUE}[3/7]${NC} Checking code formatting..."
UNFORMATTED=$(flutter format --set-exit-if-changed --dry-run lib/ test/ 2>&1 | grep -c "Formatted" || true)
if [ "$UNFORMATTED" -eq 0 ]; then
    echo -e "${GREEN}✅ All files properly formatted${NC}"
else
    echo -e "${YELLOW}⚠️  $UNFORMATTED file(s) need formatting${NC}"
    echo "   Run: flutter format lib/ test/"
    FAILED=1
fi
echo ""

# 4. Analyze code
echo -e "${BLUE}[4/7]${NC} Analyzing code..."
if flutter analyze --no-fatal-infos --no-fatal-warnings > /tmp/analyze.log 2>&1; then
    echo -e "${GREEN}✅ No analysis issues${NC}"
else
    echo -e "${RED}❌ Analysis issues found:${NC}"
    cat /tmp/analyze.log
    FAILED=1
fi
echo ""

# 5. Check for unused files
echo -e "${BLUE}[5/7]${NC} Checking for unused files..."
UNUSED_COUNT=0
for file in lib/**/*.dart; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .dart)
        # Skip main.dart and firebase_options.dart
        if [[ "$filename" != "main" && "$filename" != "firebase_options" ]]; then
            # Check if file is imported anywhere
            if ! grep -r "import.*$filename.dart" lib/ --include="*.dart" > /dev/null 2>&1; then
                if [ $UNUSED_COUNT -eq 0 ]; then
                    echo -e "${YELLOW}⚠️  Potentially unused files:${NC}"
                fi
                echo "   - $file"
                ((UNUSED_COUNT++))
            fi
        fi
    fi
done
if [ $UNUSED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ No unused files detected${NC}"
fi
echo ""

# 6. Check for common issues
echo -e "${BLUE}[6/7]${NC} Checking for common issues..."
ISSUES=0

# Check for print statements
PRINT_COUNT=$(find lib -name "*.dart" -not -path "*/test/*" -exec grep -l "print(" {} \; 2>/dev/null | wc -l)
if [ "$PRINT_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found print() in $PRINT_COUNT file(s)${NC}"
    echo "   Consider using LogService instead"
    ((ISSUES++))
fi

# Check for TODO comments
TODO_COUNT=$(find lib -name "*.dart" -exec grep -c "TODO" {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
if [ "$TODO_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $TODO_COUNT TODO comment(s)${NC}"
    echo "   Consider creating issues for these"
    ((ISSUES++))
fi

# Check for debugPrint
DEBUG_COUNT=$(find lib -name "*.dart" -exec grep -l "debugPrint" {} \; 2>/dev/null | wc -l)
if [ "$DEBUG_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found debugPrint in $DEBUG_COUNT file(s)${NC}"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ No common issues found${NC}"
fi
echo ""

# 7. Run tests (if any exist)
echo -e "${BLUE}[7/7]${NC} Running tests..."
if [ -d "test" ] && [ "$(find test -name "*_test.dart" | wc -l)" -gt 0 ]; then
    if flutter test > /dev/null 2>&1; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠️  No tests found${NC}"
    echo "   Consider adding tests for critical functionality"
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Summary                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo -e "${GREEN}   Your code is ready to commit and push.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some checks failed${NC}"
    echo -e "${RED}   Please fix the issues above before pushing.${NC}"
    exit 1
fi
