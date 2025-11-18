# ProMould Jobcard Workflow - Complete Implementation

## Overview
Major refactoring of the jobcard scanning and production tracking system. This implementation introduces a comprehensive workflow from jobcard scanning to daily production reporting.

## What Was Implemented

### 1. Updated Jobcard Data Model
**File:** `lib/utils/jobcard_models.dart`

**New Fields:**
- `jobName` - Product name (e.g., "50LT Coolbox Outer")
- `color` - Product color (e.g., "CampMastr Blue")
- `cycleWeightGrams` - Cycle weight for mould matching
- `targetCycleDay` - Daily production target
- `targetCycleNight` - Night shift production target
- `productionRows` - List of ProductionTableRow objects

**Removed Fields:**
- `fgCode` - Not needed
- `dateStarted` - Not needed
- `cycleTimeSeconds` - Not needed
- `cavity` - Not needed
- `barcode` - Consolidated into worksOrderNo

**New Model: ProductionTableRow**
```dart
- date: Date of production
- dayCounterStart/End: Machine counter values
- dayActual: Units produced (day shift)
- dayScrap: Scrap count (day shift)
- nightCounterStart/End: Machine counter values
- nightActual: Units produced (night shift)
- nightScrap: Scrap count (night shift)
- dayScrapRate: Calculated as (scrap / actual) * 100
- nightScrapRate: Calculated as (scrap / actual) * 100
```

### 2. Enhanced Jobcard Parser
**File:** `lib/services/jobcard_parser_service.dart`

**New Extraction Methods:**
- `_extractJobName()` - Extracts product name from jobcard
- `_extractColor()` - Extracts color from product description
- `_extractTargetCycleDay()` - Extracts daily target
- `_extractTargetCycleNight()` - Extracts night target
- `_extractProductionTable()` - Extracts ALL production rows from table

**Key Features:**
- Multi-line field extraction (label on one line, value on next)
- Handles commas in numbers (3,000.00 -> 3000)
- Extracts units from values (85 seconds, 1767 gram)
- Auto-detects date formats (DD/MM/YYYY, DD-MM-YY, etc.)
- Extracts multiple production table rows with dates

### 3. Updated Review Screen
**File:** `lib/screens/jobcard_review_screen.dart`

**Changes:**
- Updated form fields to match new model
- Added production table display with scrap rates
- Color-coded scrap rates (green <5%, red >5%)
- Shows all extracted production rows

**New Workflow:**
1. User reviews extracted data
2. Can edit any field
3. Clicks "Create Job"
4. System checks if job exists by Works Order No

### 4. Job Creation Workflow
**File:** `lib/screens/jobcard_review_screen.dart` - `_createJob()` method

**Logic:**
```
IF job with Works Order No exists:
  -> Call _addProductionData()
  -> Verify job is on same machine
  -> Add production rows to Daily Production Sheet
  -> Update job's shotsCompleted count
  -> Show success message
ELSE:
  -> Call _createNewJob()
  -> Show machine selection dialog
  -> Auto-match mould by cycle weight + name
  -> Create new job with all fields
  -> Add production data if any
  -> Show success message
```

**Machine Selection Dialog:**
- Lists all available machines
- Shows machine name and floor
- User selects machine for new job

**Mould Auto-Matching:**
- Finds moulds with matching cycle weight (±10% tolerance)
- If multiple matches, uses partial name matching
- Returns best match or null

### 5. Daily Production Sheet (DPS)
**File:** `lib/screens/daily_production_sheet_screen.dart`

**Features:**
- Floor selection dropdown (16A, 16B, future floors)
- Date picker for viewing specific days
- Data table with columns:
  * Machine
  * Job Name + Color
  * Works Order No
  * Day Actual
  * Day Scrap
  * Day Scrap % (color-coded)
  * Night Actual
  * Night Scrap
  * Night Scrap % (color-coded)
  * Actions (Edit/Delete)

**PDF Export:**
- Landscape A4 format
- Includes all data for selected floor and date
- Professional table layout
- Uses `printing` package for sharing

**Data Storage:**
- New Hive box: `dailyProductionBox`
- Stores per-machine, per-shift production data
- Includes counter verification values
- Syncs to Firebase

### 6. Navigation Updates
**File:** `lib/screens/role_router.dart`

- Added DPS to Manager menu
- Icon: `Icons.assignment_outlined`
- Accessible from main navigation drawer

### 7. Database Updates
**File:** `lib/main.dart`

- Added `dailyProductionBox` to core boxes
- Initialized on app startup

## Data Flow

### Scanning a Jobcard

```
1. User scans jobcard with camera
   ↓
2. Image resized to 2048px (if larger)
   ↓
3. Google ML Kit OCR extracts text
   ↓
4. Parser extracts:
   - Works Order No (JC031351)
   - Job Name (50LT Coolbox Outer)
   - Color (CampMastr Blue)
   - Cycle Weight (1767g)
   - Quantity (3000)
   - Daily Output (1016)
   - Target Day/Night (466/551)
   - Production Table Rows (all dates)
   ↓
5. Review screen shows extracted data
   ↓
6. User confirms or edits
   ↓
7. System checks if job exists
```

### If Job Exists

```
1. Verify job is on same machine
   ↓
2. For each production row:
   - Create DPS entry
   - Store date, machine, shift data
   - Calculate scrap rates
   ↓
3. Update job's shotsCompleted
   ↓
4. Sync to Firebase
   ↓
5. Show success message
```

### If New Job

```
1. Show machine selection dialog
   ↓
2. User selects machine
   ↓
3. Auto-match mould:
   - Find by cycle weight (±10%)
   - Refine by name similarity
   ↓
4. Create job with:
   - worksOrderNo (jobcard number)
   - jobName, color
   - targetShots, dailyOutput
   - cycleWeightGrams
   - targetCycleDay/Night
   - machineId, mouldId
   - status: 'Pending'
   ↓
5. Add production data if any
   ↓
6. Sync to Firebase
   ↓
7. Show success message
```

## Testing Checklist

### Phase 1: Jobcard Scanning
- [ ] Scan jobcard with large image (>4096px)
- [ ] Verify image is resized to 2048px
- [ ] Check OCR extracts text correctly
- [ ] Verify all fields are extracted:
  - [ ] Works Order No
  - [ ] Job Name
  - [ ] Color
  - [ ] Cycle Weight
  - [ ] Quantity
  - [ ] Daily Output
  - [ ] Target Day/Night
  - [ ] Production table rows
- [ ] Test "View Raw OCR Text" button
- [ ] Test "Copy" button in OCR dialog

### Phase 2: Review Screen
- [ ] All fields display correctly
- [ ] Can edit any field
- [ ] Production rows show with scrap rates
- [ ] Scrap rates color-coded correctly
- [ ] Confidence indicators work

### Phase 3: New Job Creation
- [ ] Machine selection dialog appears
- [ ] Can select machine
- [ ] Mould auto-matching works
- [ ] Job created with all fields
- [ ] Job appears in Manage Jobs
- [ ] Production data added to DPS

### Phase 4: Existing Job
- [ ] System detects existing job
- [ ] Verifies machine matches
- [ ] Production data added to DPS
- [ ] Job's shotsCompleted updated
- [ ] No duplicate job created

### Phase 5: Daily Production Sheet
- [ ] Can select floor (16A/16B)
- [ ] Can select date
- [ ] Data filters correctly
- [ ] Table shows all entries
- [ ] Scrap rates calculated correctly
- [ ] Scrap rates color-coded
- [ ] Can edit entry (when implemented)
- [ ] Can delete entry
- [ ] PDF export works
- [ ] PDF contains all data

### Phase 6: Edge Cases
- [ ] Jobcard with no production data
- [ ] Jobcard with partial data
- [ ] Multiple production rows
- [ ] Invalid date formats
- [ ] Missing fields
- [ ] Duplicate scans
- [ ] No machines available
- [ ] No moulds match

## Known Limitations

1. **Manual Entry Not Implemented**
   - DPS manual entry dialog is placeholder
   - Edit dialog is placeholder
   - Need to implement full CRUD for DPS entries

2. **Mould Matching**
   - 10% tolerance might be too strict/loose
   - Name matching is basic substring check
   - No confidence score shown to user

3. **Production Table Parsing**
   - Assumes specific table format
   - May fail with different layouts
   - Date parsing could be more robust

4. **Machine Verification**
   - Only checks if machine matches
   - Doesn't handle machine changes mid-job
   - No warning if machine is offline

## Future Enhancements

1. **DPS Manual Entry**
   - Full form for manual data entry
   - Validation and error handling
   - Support for partial shifts

2. **DPS Edit Functionality**
   - Edit existing entries
   - Recalculate scrap rates
   - Audit trail

3. **Advanced Mould Matching**
   - Show confidence score
   - Allow manual selection
   - Learn from user corrections

4. **Production Analytics**
   - Trend analysis
   - Scrap rate alerts
   - Efficiency metrics

5. **Raw Materials Integration**
   - Extract material data from jobcard
   - Track material usage
   - Inventory management

## Breaking Changes

⚠️ **Important:** This is a major refactoring that changes the JobcardData model structure.

**Migration Notes:**
- Old jobcard scans will not work with new model
- Existing jobs are compatible (new fields are optional)
- DPS is new feature, no migration needed

**Backward Compatibility:**
- Jobs created before this update will work
- Old jobcard images need to be rescanned
- No data loss for existing jobs

## Deployment

**Build Number:** 125+

**Steps:**
1. Pull latest code
2. Run `flutter pub get` to install `printing` package
3. Build APK: GitHub Actions will auto-build
4. Test on device with actual jobcards
5. Monitor for errors in production

**Rollback Plan:**
If issues occur:
1. Revert to previous build
2. Fix issues in development
3. Re-test thoroughly
4. Deploy again

## Support

**Common Issues:**

1. **"No machines available"**
   - Add machines in Manage Machines first
   - Ensure machines have floor assigned

2. **"Mould not found"**
   - Add moulds in Manage Moulds
   - Ensure cycle weight is set
   - Check tolerance (±10%)

3. **"Job already exists"**
   - This is expected behavior
   - Production data will be added to existing job
   - Check DPS for new entries

4. **OCR not extracting fields**
   - Ensure good lighting
   - Hold camera steady
   - Capture entire jobcard
   - Use "View Raw OCR Text" to debug

## Credits

Implemented by: Ona AI Assistant
Co-authored-by: Ona <no-reply@ona.com>
Date: November 18, 2025
Version: 7.2 Build 125+
