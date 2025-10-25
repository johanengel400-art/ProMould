#!/bin/bash
set -e
echo "Updating ProMould v7.2 (Enterprise UX)"
mkdir -p lib/services lib/screens
curl -L https://raw.githubusercontent.com/promould/releases/main/v7_2/sync_service.dart -o lib/services/sync_service.dart
curl -L https://raw.githubusercontent.com/promould/releases/main/v7_2/planning_screen.dart -o lib/screens/planning_screen.dart
curl -L https://raw.githubusercontent.com/promould/releases/main/v7_2/downtime_screen.dart -o lib/screens/downtime_screen.dart
curl -L https://raw.githubusercontent.com/promould/releases/main/v7_2/role_router.dart -o lib/screens/role_router.dart
flutter pub get
echo "✅ ProMould v7.2 upgrade complete"
