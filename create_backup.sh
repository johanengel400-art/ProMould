#!/bin/bash

# ProMould Backup Script
# Creates a complete backup of the ProMould application

BACKUP_NAME="ProMould_v7.1_Backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="/tmp/$BACKUP_NAME"
ZIP_FILE="$BACKUP_NAME.zip"

echo "Creating ProMould backup..."
echo "Backup name: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Copy all project files except build artifacts and dependencies
rsync -av --progress \
  --exclude='.git' \
  --exclude='build/' \
  --exclude='.dart_tool/' \
  --exclude='.idea/' \
  --exclude='*.iml' \
  --exclude='.flutter-plugins' \
  --exclude='.flutter-plugins-dependencies' \
  --exclude='.packages' \
  --exclude='android/.gradle/' \
  --exclude='android/app/build/' \
  --exclude='android/build/' \
  --exclude='ios/Pods/' \
  --exclude='ios/.symlinks/' \
  --exclude='ios/Flutter/Flutter.framework' \
  --exclude='ios/Flutter/Flutter.podspec' \
  --exclude='node_modules/' \
  ./ "$BACKUP_DIR/"

# Create README for the backup
cat > "$BACKUP_DIR/BACKUP_README.md" << 'EOF'
# ProMould v7.1 - Backup Archive

## Contents
This backup contains the complete ProMould v7.1 Smart Factory application source code.

## What's Included
- Complete Flutter application source code
- All screens and services
- Analytics and reporting features
- Predictive maintenance system
- Custom report builder
- Checklist management system
- Firebase integration
- Documentation

## What's Excluded (for size optimization)
- Build artifacts (build/, .dart_tool/)
- Dependencies (can be restored with `flutter pub get`)
- IDE configuration files
- Git history (use GitHub for version control)
- Platform-specific build outputs

## Restoration Instructions

### Prerequisites
1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Install Android Studio or Xcode (for mobile development)
3. Install Git

### Steps to Restore

1. **Extract the backup:**
   ```bash
   unzip ProMould_v7.1_Backup_*.zip
   cd ProMould_v7.1_Backup_*
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

4. **Run the app:**
   ```bash
   flutter run
   ```

### Build for Production

**Android:**
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Features Included in v7.1

### Core Features
- Real-time production monitoring
- Machine status tracking
- Job queue management
- Daily input tracking
- Downtime logging
- Quality control and issue tracking

### Analytics & Reporting
- Real-time KPI dashboard
- Predictive analytics for machine failures
- Custom report builder (5 report types)
- Scheduled reports with automation
- Multi-format export (CSV, PDF)

### Checklist System
- Digital checklist management
- Progress tracking
- PDF/CSV export
- Completion history

### User Management
- Role-based access control (Admin, Manager, Setter, Operator)
- Multi-level permissions
- Operator machine assignments

### Integration
- Firebase Firestore for cloud sync
- Firebase Storage for media
- Background sync with WorkManager
- Offline-first architecture with Hive

## Technical Stack
- **Framework:** Flutter 3.3+
- **State Management:** Provider pattern with Hive
- **Database:** Hive (local) + Firestore (cloud)
- **Charts:** fl_chart, Syncfusion
- **PDF Generation:** pdf package
- **Background Tasks:** WorkManager

## Support
For issues or questions:
- GitHub: [Your Repository URL]
- Documentation: See ANALYTICS_FEATURES.md
- Main README: README.md

## Version History
- v7.1.0 (2024): Analytics, reporting, and predictive maintenance
- v7.0.0 (2024): Core production management system

## License
[Your License Information]

---
Backup created: $(date)
EOF

# Create zip file
cd /tmp
zip -r "$ZIP_FILE" "$BACKUP_NAME" -x "*.DS_Store"

# Move to original directory
mv "$ZIP_FILE" /workspaces/ProMould/

# Cleanup
rm -rf "$BACKUP_DIR"

echo ""
echo "✅ Backup created successfully!"
echo "📦 File: /workspaces/ProMould/$ZIP_FILE"
echo "📊 Size: $(du -h /workspaces/ProMould/$ZIP_FILE | cut -f1)"
echo ""
echo "To download, use:"
echo "  scp or download from your file manager"
