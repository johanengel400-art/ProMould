#!/bin/bash

echo "🔥 Firebase Connection Test"
echo "=========================="
echo ""

# Test 1: Check if Firebase CLI is installed
echo "1. Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo "   ✅ Firebase CLI installed: $(firebase --version)"
else
    echo "   ❌ Firebase CLI not installed"
    echo "   Install with: npm install -g firebase-tools"
fi
echo ""

# Test 2: Check Firebase project
echo "2. Checking Firebase project..."
PROJECT_ID="promould-ed22a"
echo "   Project ID: $PROJECT_ID"
echo ""

# Test 3: Check google-services.json
echo "3. Checking google-services.json..."
if [ -f "android/app/google-services.json" ]; then
    echo "   ✅ google-services.json exists"
    PACKAGE_NAME=$(grep -o '"package_name": "[^"]*"' android/app/google-services.json | cut -d'"' -f4)
    echo "   Package name: $PACKAGE_NAME"
else
    echo "   ❌ google-services.json not found"
fi
echo ""

# Test 4: Check firebase_options.dart
echo "4. Checking firebase_options.dart..."
if [ -f "lib/firebase_options.dart" ]; then
    echo "   ✅ firebase_options.dart exists"
    API_KEY=$(grep -o "apiKey: '[^']*'" lib/firebase_options.dart | head -1 | cut -d"'" -f2)
    echo "   Android API Key: ${API_KEY:0:20}..."
else
    echo "   ❌ firebase_options.dart not found"
fi
echo ""

# Test 5: Check security rules files
echo "5. Checking security rules..."
if [ -f "firestore.rules" ]; then
    echo "   ✅ firestore.rules exists"
else
    echo "   ⚠️  firestore.rules not found (created now)"
fi

if [ -f "storage.rules" ]; then
    echo "   ✅ storage.rules exists"
else
    echo "   ⚠️  storage.rules not found (created now)"
fi
echo ""

# Test 6: Test Firebase API endpoint
echo "6. Testing Firebase API connectivity..."
API_KEY=$(grep -o "apiKey: '[^']*'" lib/firebase_options.dart | head -1 | cut -d"'" -f2)
if [ ! -z "$API_KEY" ]; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents" -H "X-Goog-Api-Key: $API_KEY")
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "403" ]; then
        echo "   ✅ Firebase API reachable (HTTP $RESPONSE)"
        if [ "$RESPONSE" = "403" ]; then
            echo "   ⚠️  Access denied - check security rules"
        fi
    else
        echo "   ❌ Firebase API unreachable (HTTP $RESPONSE)"
    fi
else
    echo "   ⚠️  Could not extract API key"
fi
echo ""

echo "=========================="
echo "📋 Summary"
echo "=========================="
echo ""
echo "Next steps:"
echo "1. If Firebase CLI is installed, run: firebase login"
echo "2. Deploy security rules: firebase deploy --only firestore:rules,storage:rules"
echo "3. Or manually update rules in Firebase Console"
echo "4. See FIREBASE_FIX_GUIDE.md for detailed instructions"
echo ""
