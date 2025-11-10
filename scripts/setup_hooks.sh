#!/bin/bash
# Setup Git hooks for ProMould

echo "🔧 Setting up Git hooks..."

# Configure Git to use custom hooks directory
git config core.hooksPath .githooks

echo "✅ Git hooks configured!"
echo ""
echo "Pre-commit hook will now run automatically before each commit."
echo "It will check:"
echo "  - Code formatting"
echo "  - Code analysis"
echo "  - Common issues"
echo ""
echo "To skip hooks (not recommended): git commit --no-verify"
