# Jobcard Parser Implementation

## Overview
Implemented automated jobcard scanning and parsing feature that uses OCR and barcode scanning to extract job data from physical jobcard images.

## Features Implemented

### 1. Data Models (`lib/utils/jobcard_models.dart`)
- `ConfidenceValue<T>` - Wraps extracted values with confidence scores
- `JobcardData` - Main model matching ONA_jobcard_parser_spec.md schema
- `RawMaterialEntry` - Raw materials table data
- `JobcardCounters` - Day/night shift counters
- `VerificationIssue` - Tracks low-confidence fields

### 2. Parser Service (`lib/services/jobcard_parser_service.dart`)
- Uses Google ML Kit for OCR text recognition
- Uses Google ML Kit for barcode scanning
- Extracts structured data from OCR text using pattern matching
- Assigns confidence scores to each field
- Flags fields with confidence < 0.6 for verification

**Extracted Fields:**
- Works Order No (from barcode or text)
- FG Code
- Date Started (normalized to ISO format)
- Quantity to Manufacture
- Daily Output
- Cycle Time (seconds)
- Cycle Weight (grams)
- Cavity count
- Raw Materials table
- Day/Night counters

### 3. Image Preprocessing (`lib/utils/image_preprocessing.dart`)
- Auto-rotation based on dimensions
- Auto-crop to remove borders
- Grayscale conversion
- Contrast enhancement
- Denoising/despeckle
- Sharpening
- Resize for optimal OCR performance

### 4. Capture Screen (`lib/screens/jobcard_capture_screen.dart`)
- Camera capture option
- Gallery selection option
- Permission handling
- Processing progress indicator
- Tips for best capture results

### 5. Review Screen (`lib/screens/jobcard_review_screen.dart`)
- Displays extracted data with confidence indicators
- Color-coded confidence levels:
  - Green (≥80%): High confidence
  - Orange (60-79%): Medium confidence
  - Red (<60%): Low confidence, needs verification
- Editable fields for corrections
- Image preview
- Verification issues list
- Creates job with jobcard metadata

### 6. Integration
- Added scan button to Manage Jobs screen
- Floating action button for quick access
- Seamless integration with existing job creation flow

## Dependencies Added

```yaml
# OCR and barcode scanning
google_mlkit_text_recognition: ^0.13.0
google_mlkit_barcode_scanning: ^0.12.0
image: ^4.1.7
camera: ^0.11.0+2
```

## Usage Flow

1. **Capture**: User taps scan button → chooses camera or gallery
2. **Preprocess**: Image is automatically enhanced for OCR
3. **Parse**: OCR extracts text, barcode scanner reads barcode
4. **Extract**: Parser extracts structured data with confidence scores
5. **Review**: User reviews and edits extracted data
6. **Create**: Job is created with jobcard metadata

## Confidence Scoring

- **Barcode**: 1.0 (authoritative)
- **Pattern matches**: 0.75-0.8
- **Table data**: 0.6
- **Not found**: 0.0

Fields with confidence < 0.6 are flagged for manual verification.

## Job Data Extensions

Jobs created from jobcards include additional fields:
- `worksOrderNo`: Works order number
- `fgCode`: Finished goods code
- `dateStarted`: Start date from jobcard
- `dailyOutput`: Daily output target
- `cycleTimeSeconds`: Cycle time
- `cycleWeightGrams`: Cycle weight
- `cavity`: Cavity count
- `jobcardImagePath`: Path to original image
- `jobcardScannedAt`: Timestamp of scan
- `jobcardConfidence`: Overall confidence score

## Testing Checklist

### Before Running
- [ ] Run `flutter pub get` to install dependencies
- [ ] Ensure camera permissions in AndroidManifest.xml/Info.plist
- [ ] Test on physical device (camera required)

### Test Cases
1. **Camera Capture**
   - [ ] Grant camera permission
   - [ ] Capture clear jobcard image
   - [ ] Verify preprocessing works
   - [ ] Check OCR extraction

2. **Gallery Selection**
   - [ ] Grant storage permission
   - [ ] Select existing jobcard image
   - [ ] Verify parsing works

3. **Data Extraction**
   - [ ] Works order number extracted correctly
   - [ ] FG code extracted
   - [ ] Date parsed and normalized
   - [ ] Numeric fields extracted
   - [ ] Confidence scores assigned

4. **Review & Edit**
   - [ ] Low confidence fields highlighted
   - [ ] Can edit all fields
   - [ ] Image preview displays
   - [ ] Verification issues shown

5. **Job Creation**
   - [ ] Job created successfully
   - [ ] All data saved to Hive
   - [ ] Synced to Firebase
   - [ ] Returns to jobs list

## Known Limitations

1. **OCR Accuracy**: Depends on image quality, lighting, and text clarity
2. **Table Parsing**: Simplified implementation - may need refinement for complex tables
3. **Offline Only**: Uses on-device ML Kit (no cloud API)
4. **English Only**: Pattern matching optimized for English text

## Future Enhancements

1. **Cloud OCR**: Option to use Google Cloud Vision API for better accuracy
2. **Template Learning**: Train on specific jobcard layouts
3. **Batch Scanning**: Scan multiple jobcards at once
4. **History**: View previously scanned jobcards
5. **Export**: Export parsed data to CSV/PDF
6. **Multi-language**: Support for other languages

## Troubleshooting

### OCR Not Working
- Ensure good lighting when capturing
- Keep jobcard flat and in focus
- Try preprocessing manually
- Check ML Kit dependencies installed

### Low Confidence Scores
- Improve image quality
- Ensure text is clear and readable
- Adjust preprocessing parameters
- Manually correct in review screen

### Permission Errors
- Check AndroidManifest.xml has camera/storage permissions
- Check Info.plist has camera/photo library usage descriptions
- Request permissions at runtime

## Files Created

```
lib/
├── screens/
│   ├── jobcard_capture_screen.dart
│   └── jobcard_review_screen.dart
├── services/
│   └── jobcard_parser_service.dart
└── utils/
    ├── jobcard_models.dart
    └── image_preprocessing.dart
```

## Next Steps

1. Run `flutter pub get`
2. Test on physical device
3. Capture sample jobcard
4. Review extracted data
5. Create job from jobcard
6. Verify job appears in jobs list

## Support

For issues or questions about the jobcard parser:
1. Check image quality and lighting
2. Review confidence scores
3. Manually correct low-confidence fields
4. Report persistent issues with sample images
