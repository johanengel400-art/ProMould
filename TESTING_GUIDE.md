# Testing Guide for ProMould v7.2

## Prerequisites
1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Verify no analysis errors:
   ```bash
   flutter analyze --no-fatal-infos --no-fatal-warnings
   ```

## Feature Testing Checklist

### 1. Live Progress System
**Location**: Dashboard, Planning, Timeline screens

**Test Steps**:
1. Start a job on a machine
2. Observe the shot count increasing automatically every 5 seconds
3. Formula: `estimated_shots = manual_shots + (elapsed_time / cycle_time)`
4. Go to Daily Input screen and enter actual shots
5. Verify the baseline resets and continues counting from new value

**Expected Results**:
- ✅ Shot counts update in real-time without manual refresh
- ✅ Progress bars move smoothly
- ✅ Manual input resets the baseline correctly
- ✅ ETA calculations adjust based on live progress

### 2. Scrap Rate Tracking
**Location**: Dashboard, Planning screens

**Test Steps**:
1. View machines on dashboard
2. Check scrap rate badges on machine cards
3. Verify color coding:
   - Green: < 2%
   - Yellow: 2-5%
   - Orange: 5-10%
   - Red: > 10%

**Expected Results**:
- ✅ Scrap rates display correctly
- ✅ Colors match thresholds
- ✅ Rates update when new inputs are added

### 3. Dashboard V2
**Location**: Main dashboard (DashboardScreenV2)

**Test Steps**:
1. Navigate to dashboard
2. Check alerts panel at top
3. Verify quick stats cards (running machines, jobs, scrap rate, issues)
4. View machine cards with live progress
5. Test floor filter dropdown

**Expected Results**:
- ✅ Professional gradient design loads
- ✅ Alerts show urgent issues
- ✅ Stats are accurate
- ✅ Machine cards update every 2 seconds
- ✅ Floor filter works correctly

### 4. Timeline V2
**Location**: Timeline screen (TimelineScreenV2)

**Test Steps**:
1. Navigate to timeline
2. Scroll through machine groups
3. Check running jobs (blue badges)
4. Check queued jobs (orange badges with queue position)
5. Verify progress bars and ETAs

**Expected Results**:
- ✅ Card-based vertical layout is mobile-friendly
- ✅ Jobs grouped by machine
- ✅ Status badges clear and visible
- ✅ Progress bars accurate
- ✅ ETAs calculated correctly

### 5. Mould Change Scheduler
**Location**: Mould Changes screen (MouldChangeSchedulerScreen)

**Test Steps**:
1. Navigate to mould changes
2. Click "Schedule Change" button
3. Select machine, from/to moulds, date/time, setter
4. Save the change
5. View scheduled changes list
6. Update status (Scheduled → In Progress → Completed)
7. Check overdue indicators

**Expected Results**:
- ✅ Form validates all fields
- ✅ Changes save to database
- ✅ Status updates work
- ✅ Overdue changes highlighted in red
- ✅ Filter by status works

### 6. Health Score System
**Location**: Dashboard V2, Machine Detail

**Test Steps**:
1. View machine health scores on dashboard
2. Check score calculation:
   - Uptime: 40 points
   - Quality: 30 points
   - Productivity: 30 points
   - Total: 0-100
3. Verify color coding:
   - Green: 85-100 (Excellent)
   - Yellow: 60-84 (Good)
   - Orange: 40-59 (Fair)
   - Red: 0-39 (Poor)

**Expected Results**:
- ✅ Scores calculate correctly
- ✅ Colors match ranges
- ✅ Scores update with new data

### 7. Smart Notifications
**Location**: Dashboard alerts panel

**Test Steps**:
1. Create conditions for notifications:
   - Job near completion (30 min before)
   - High scrap rate (>5%)
   - Maintenance due
   - Mould change scheduled
   - Machine breakdown
   - Quality hold
2. Check alerts panel
3. Verify priority sorting (Critical > High > Medium > Low)

**Expected Results**:
- ✅ Notifications appear in alerts panel
- ✅ Sorted by priority
- ✅ Auto-refresh every 30 seconds
- ✅ Actionable information provided

### 8. Job Queue Manager
**Location**: Job Queue screen (JobQueueManagerScreen)

**Test Steps**:
1. Navigate to job queue
2. View queued jobs for each machine
3. Drag and drop to reorder jobs
4. Verify queue positions update
5. Try to reorder running job (should be protected)

**Expected Results**:
- ✅ Jobs display with queue positions
- ✅ Drag-and-drop works smoothly
- ✅ Queue positions save correctly
- ✅ Running jobs cannot be reordered

### 9. My Tasks (Setter View)
**Location**: My Tasks screen (MyTasksScreen)

**Test Steps**:
1. Login as a setter
2. Navigate to My Tasks
3. View assigned mould changes
4. Check today's checklists
5. View open issues
6. Check overdue indicators

**Expected Results**:
- ✅ Only assigned tasks shown
- ✅ Overdue items highlighted
- ✅ Priority badges visible
- ✅ Can navigate to detail screens

### 10. Quality Control
**Location**: Quality Control screen (QualityControlScreen)

**Test Steps**:
1. Navigate to Quality Control
2. Create inspection:
   - Select job
   - Choose type (First Article, In-Process, Final, Random)
   - Enter result (Pass/Fail)
   - Add notes
3. Create quality hold:
   - Select job
   - Choose severity (Low, Medium, High, Critical)
   - Enter reason
   - Specify action (Release/Scrap)
4. View inspection history
5. View active holds

**Expected Results**:
- ✅ Inspections save correctly
- ✅ Holds create successfully
- ✅ History displays all records
- ✅ Severity colors match levels
- ✅ Can filter by job/date

### 11. Scrap Trend Chart
**Location**: Dashboard widgets

**Test Steps**:
1. View scrap trend chart
2. Check 7-day data
3. Verify target line at 5%
4. Hover over data points for tooltips

**Expected Results**:
- ✅ Chart displays correctly
- ✅ Data accurate for last 7 days
- ✅ Target line visible
- ✅ Tooltips show exact values
- ✅ Gradient area fills properly

### 12. OEE Gauge
**Location**: Dashboard widgets, Machine Detail

**Test Steps**:
1. View OEE gauge widget
2. Check gauge ranges:
   - Red: 0-40% (Poor)
   - Orange: 40-60% (Fair)
   - Yellow: 60-85% (Good)
   - Green: 85-100% (World Class)
3. Verify needle position matches OEE value

**Expected Results**:
- ✅ Gauge renders correctly
- ✅ Colors match ranges
- ✅ Needle points to correct value
- ✅ Smooth animations

## Performance Testing

### Load Testing
1. Add 50+ machines
2. Add 100+ jobs
3. Navigate between screens
4. Check UI responsiveness

**Expected Results**:
- ✅ No lag or stuttering
- ✅ Smooth scrolling
- ✅ Fast screen transitions

### Background Services
1. Let app run for 30+ minutes
2. Verify live progress continues updating
3. Check notification service still running
4. Confirm no memory leaks

**Expected Results**:
- ✅ Services run continuously
- ✅ No crashes or freezes
- ✅ Memory usage stable

## Integration Testing

### Firebase Sync
1. Make changes on one device
2. Check sync to Firebase
3. Verify changes appear on other devices

**Expected Results**:
- ✅ Changes sync within 5 seconds
- ✅ No data loss
- ✅ Conflict resolution works

### Offline Mode
1. Disable network
2. Make changes locally
3. Re-enable network
4. Verify changes sync

**Expected Results**:
- ✅ App works offline
- ✅ Changes queue for sync
- ✅ Sync completes when online

## Bug Reporting

If you find issues, document:
1. **Steps to reproduce**
2. **Expected behavior**
3. **Actual behavior**
4. **Screenshots/logs**
5. **Device/OS version**

## Notes
- Test on both Android and iOS if possible
- Test on different screen sizes (phone, tablet)
- Test with different user roles (Operator, Setter, Supervisor, Manager)
- Test edge cases (empty data, large datasets, network issues)
