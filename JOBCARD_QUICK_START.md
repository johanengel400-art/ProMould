# Jobcard Scanner - Quick Start Guide

## Setup (One-time)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 3. iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan jobcards</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to select jobcard images</string>
```

## How to Use

### Step 1: Access Scanner
1. Open ProMould app
2. Navigate to **Manage Jobs** screen
3. Tap the **green scan button** (floating action button)

### Step 2: Capture Jobcard
Choose one option:
- **Take Photo**: Capture with camera
- **Choose from Gallery**: Select existing image

**Tips for Best Results:**
- Use good lighting
- Keep jobcard flat
- Capture entire document
- Avoid shadows and glare

### Step 3: Review Extracted Data
The app will automatically:
1. Preprocess the image
2. Run OCR and barcode scanning
3. Extract structured data
4. Show confidence scores

**Confidence Indicators:**
- 🟢 Green (80-100%): High confidence
- 🟠 Orange (60-79%): Medium confidence - review recommended
- 🔴 Red (0-59%): Low confidence - manual correction needed

### Step 4: Verify & Edit
1. Review all extracted fields
2. Check confidence indicators
3. Edit any incorrect values
4. Pay attention to fields marked in red/orange

### Step 5: Create Job
1. Tap **Create Job** button
2. Job is created with all jobcard data
3. Returns to jobs list

## What Gets Extracted

### Core Fields
- ✅ Works Order No
- ✅ FG Code
- ✅ Date Started
- ✅ Quantity to Manufacture
- ✅ Daily Output
- ✅ Cycle Time (seconds)
- ✅ Cycle Weight (grams)
- ✅ Cavity count

### Additional Data
- Raw Materials table
- Day/Night counters
- Barcode (if present)
- Original image reference

## Troubleshooting

### "Failed to extract data"
**Solution:**
- Retake photo with better lighting
- Ensure text is clear and readable
- Try selecting from gallery instead
- Check image is not blurry

### Low Confidence Scores
**Solution:**
- Review and manually correct fields
- Improve image quality for future scans
- Ensure jobcard is flat when capturing

### Permission Denied
**Solution:**
- Go to device Settings → Apps → ProMould
- Enable Camera and Storage permissions
- Restart app

### Camera Not Opening
**Solution:**
- Check camera permissions granted
- Close and reopen app
- Try "Choose from Gallery" instead

## Best Practices

### For Operators
1. **Clean Jobcards**: Keep jobcards clean and readable
2. **Good Lighting**: Scan in well-lit area
3. **Flat Surface**: Place jobcard on flat surface
4. **Review Data**: Always review extracted data before creating job

### For Managers
1. **Train Staff**: Show operators how to scan properly
2. **Quality Check**: Periodically review scanned jobs
3. **Feedback Loop**: Report common OCR issues
4. **Backup**: Keep physical jobcards as backup

## Feature Benefits

✅ **Faster Job Creation**: Scan instead of manual entry
✅ **Reduced Errors**: OCR eliminates typos
✅ **Digital Record**: Image stored with job
✅ **Confidence Scores**: Know which fields to verify
✅ **Offline Capable**: Works without internet

## Example Workflow

```
1. Receive physical jobcard
   ↓
2. Open ProMould → Manage Jobs
   ↓
3. Tap green scan button
   ↓
4. Take photo of jobcard
   ↓
5. Wait 3-5 seconds for processing
   ↓
6. Review extracted data
   ↓
7. Correct any red/orange fields
   ↓
8. Tap "Create Job"
   ↓
9. Job ready for assignment!
```

## Support

**Need Help?**
- Check JOBCARD_PARSER_IMPLEMENTATION.md for technical details
- Review confidence scores for data quality
- Contact support with sample images for persistent issues

**Reporting Issues:**
Include:
- Screenshot of review screen
- Original jobcard image (if possible)
- Description of incorrect extraction
