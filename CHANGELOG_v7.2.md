# ProMould v7.2 Changelog

## Overview
Version 7.2 introduces major improvements to job assignment, status management, and real-time dashboard updates.

## Major Features

### 1. Fixed Job Assignment System
**Problem:** Jobs were assigned but never started, machine status didn't update, dashboard didn't reflect changes.

**Solution:**
- Complete job lifecycle management: Pending → Running → Finished
- Automatic machine status updates when jobs are assigned/completed
- First job assigned to a machine starts immediately (Running status)
- Additional jobs queue properly (Queued status)
- When a job finishes, the next queued job starts automatically
- Machine goes Idle when no more jobs remain

### 2. Real-Time Dashboard Updates
**Problem:** Dashboard only updated on app restart, not when jobs changed.

**Solution:**
- Converted DashboardScreen to StatefulWidget
- Added listeners to both machinesBox and jobsBox
- Dashboard now rebuilds automatically when any job data changes
- Real-time progress tracking for all machines

### 3. Improved Job Management
**New Features:**
- Jobs created without machine assignment (status: Pending)
- Manual "Start" button for queued jobs (testing/override)
- Better visibility of job status and machine assignment
- Shows which machine each job is assigned to

### 4. Enhanced Planning Screen
**Improvements:**
- Only shows unassigned jobs in assignment dialog
- Properly updates job machineId and status when assigning
- Checks if machine already has running jobs
- Updates machine status to Running when first job assigned
- Queues additional jobs automatically

### 5. Smart Daily Input
**Auto-progression:**
- When job reaches target shots, automatically marks as Finished
- Starts next queued job for that machine
- Sets machine to Idle if no more jobs
- Seamless job transitions without manual intervention

## Technical Changes

### Files Modified
1. **lib/screens/dashboard_screen.dart**
   - StatelessWidget → StatefulWidget
   - Added dual box listeners (machines + jobs)
   - Real-time state updates

2. **lib/screens/planning_screen.dart**
   - Job assignment updates both job and machine
   - Filters unassigned jobs only
   - Automatic status management
   - Removed unused queueBox system

3. **lib/screens/manage_jobs_screen.dart**
   - Jobs created as "Pending" status
   - Removed machine selection from creation
   - Added manual start button
   - Shows machine assignment status

4. **lib/screens/daily_input_screen.dart**
   - Auto-start next queued job on completion
   - Machine status management
   - Proper job lifecycle handling

5. **.github/workflows/build-android.yml**
   - Fixed build_runner command for GitHub Actions
   - Added code analysis step
   - Updated version numbers to v7.2
   - Added verbose build output

## Job Status Flow

```
CREATE JOB
    ↓
Status: "Pending" (no machine assigned)
    ↓
ASSIGN IN PLANNING SCREEN
    ↓
First job for machine:
  - Job Status: "Running"
  - Machine Status: "Running"
  - startTime: set
    ↓
Additional jobs:
  - Job Status: "Queued"
    ↓
DAILY INPUT (shots completed)
    ↓
Job reaches target:
  - Job Status: "Finished"
  - endTime: set
  - Next queued job → "Running"
    ↓
No more queued jobs:
  - Machine Status: "Idle"
```

## Commits

### Dashboard Fixes
- `778e1bc` - Fix: Dashboard now updates when jobs or planning changes

### Job Assignment System
- `2915e37` - Fix: Complete job assignment and status update system

### Build Fixes
- `a31b24d` - Trigger v7.2.1 build - Job assignment fixes
- `05ae395` - Fix: Update GitHub Actions workflow for v7.2
- `17a5565` - Trigger v7.2.2 build - Workflow fixes

## Testing Checklist

- [ ] Create a new job (should be Pending status)
- [ ] Assign job to machine in Planning screen
- [ ] Verify machine status changes to Running
- [ ] Verify dashboard shows job progress
- [ ] Add shots in Daily Input
- [ ] Verify dashboard updates in real-time
- [ ] Complete job (reach target shots)
- [ ] Verify next queued job starts automatically
- [ ] Verify machine goes Idle when no more jobs
- [ ] Test manual start button in Jobs screen

## Known Issues
None currently identified.

## Future Enhancements
- Job priority management
- Estimated completion time display
- Job history and analytics
- Batch job assignment
- Job templates

## Version Info
- Version: 7.2
- Build: GitHub Actions automated
- Flutter: 3.24.5 (stable)
- Release: ProMould-v7.2.apk
