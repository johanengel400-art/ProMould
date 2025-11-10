# Overrunning Status - Complete Fix

**Date:** November 10, 2024  
**Status:** ✅ Fixed and Ready to Test

---

## 🎯 What Was Fixed

### Problem
Jobs were not automatically changing to "Overrunning" status when the live progress tracking detected they reached the target shot count.

### Root Cause
The `LiveProgressService` was:
1. **Clamping shots to target** - preventing shots from exceeding target
2. **Auto-finishing jobs** - changing status to 'Finished' when target reached
3. **Only tracking 'Running' jobs** - not continuing to track after status change

---

## ✅ Solution Implemented

### Changes Made

**1. LiveProgressService (lib/services/live_progress_service.dart)**
- ✅ Removed shot count clamping - shots can now exceed target
- ✅ Changed auto-finish to auto-overrun - status changes to 'Overrunning' instead of 'Finished'
- ✅ Continue tracking both 'Running' and 'Overrunning' jobs
- ✅ Never auto-finish jobs - requires manual finish button

**2. DailyInputScreen (lib/screens/daily_input_screen.dart)**
- ✅ Check target shots on manual input
- ✅ Change status to 'Overrunning' if shots >= target
- ✅ Added debug logging

**3. ManageJobsScreen (lib/screens/manage_jobs_screen.dart)**
- ✅ Show 'Overrunning' status in red
- ✅ Final shot count dialog when finishing
- ✅ Archive finished jobs to Firestore by date
- ✅ Added debug logging

---

## 🔄 How It Works Now

### Automatic Overrunning (Live Progress)
```
Job Running → Live progress tracks shots every 5 seconds
              ↓
         Shots >= Target?
              ↓
         Status = 'Overrunning' (RED)
              ↓
         Continue tracking shots
              ↓
         Shots keep incrementing
              ↓
         Operator presses "Finish Job"
              ↓
         Dialog: Enter final shot count
              ↓
         Job archived to finishedJobs/{date}
```

### Manual Input Overrunning
```
Job Running → Operator enters shots in Daily Input
              ↓
         Total shots >= Target?
              ↓
         Status = 'Overrunning' (RED)
              ↓
         Job continues running
              ↓
         More shots can be added
              ↓
         Operator presses "Finish Job"
              ↓
         Dialog: Enter final shot count
              ↓
         Job archived to finishedJobs/{date}
```

---

## 🎨 Visual Changes

### Job Status Colors
- **Running (Green):** Shots < Target, job in progress
- **Overrunning (Red):** Shots >= Target, job continues ← **NOW WORKS AUTOMATICALLY**
- **Paused (Yellow):** Job temporarily stopped
- **Finished (Blue):** Job completed and archived

### When Status Changes
1. **Live Progress (every 5 seconds):**
   - Calculates estimated shots based on cycle time
   - If shots >= target AND status == 'Running'
   - Changes status to 'Overrunning'
   - Logs: "Job {id} reached target, status changed to Overrunning"

2. **Manual Input (when operator enters shots):**
   - Calculates total shots
   - If total >= target AND status == 'Running'
   - Changes status to 'Overrunning'
   - Logs: "DEBUG: Changed status to Overrunning!"

---

## 🧪 Testing Instructions

### Test 1: Live Progress Overrunning
1. Create job with target = 100 shots
2. Set mould cycle time = 10 seconds
3. Start the job
4. Wait ~17 minutes (100 shots × 10 sec / 60)
5. **Expected:** Status automatically changes to red "Overrunning"
6. Wait another 5 minutes
7. **Expected:** Shots continue incrementing past 100
8. Press "Finish Job"
9. **Expected:** Dialog asks for final shot count
10. Enter final count and confirm
11. **Expected:** Job removed from active list

### Test 2: Manual Input Overrunning
1. Create job with target = 10 shots (small for quick testing)
2. Start the job
3. Go to Daily Input
4. Enter 10 shots
5. **Expected:** Status immediately changes to red "Overrunning"
6. Enter 5 more shots
7. **Expected:** Total shows 15, status still "Overrunning"
8. Go to Manage Jobs
9. Press "Finish Job"
10. **Expected:** Dialog shows final count = 15
11. Confirm
12. **Expected:** Job archived

### Test 3: Debug Logging
Run the app with logging enabled:
```bash
adb logcat | grep DEBUG
```

**Expected logs when reaching target:**
```
DEBUG: newTotal=100, targetShots=100, currentStatus=Running
DEBUG: Changed status to Overrunning!
DEBUG Job ProductName: status=Overrunning, shots=100/100
```

**Expected logs from LiveProgressService:**
```
Job abc123 reached target, status changed to Overrunning
```

---

## 📊 Code Changes Summary

### Before
```dart
// LiveProgressService - OLD
final currentShots = estimatedTotalShots.clamp(baselineShots, targetShots);

if (currentShots >= targetShots && targetShots > 0) {
  updatedJob['status'] = 'Finished';  // ❌ Auto-finished
  updatedJob['endTime'] = now.toIso8601String();
  await _handleJobCompletion(jobId, updatedJob);
}
```

### After
```dart
// LiveProgressService - NEW
final currentShots = estimatedTotalShots;  // ✅ No clamping

if (currentShots >= targetShots && targetShots > 0 && updatedJob['status'] == 'Running') {
  updatedJob['status'] = 'Overrunning';  // ✅ Changes to Overrunning
  updatedJob['overrunStartTime'] = now.toIso8601String();
  LogService.info('Job $jobId reached target, status changed to Overrunning');
}

// ✅ Never auto-finishes, just saves updated job
await jobsBox.put(jobId, updatedJob);
```

---

## 🔍 Troubleshooting

### Issue: Status not changing to Overrunning

**Check 1: Is live progress running?**
```dart
// Should see in logs every 5 seconds:
LiveProgressService: Starting real-time progress updates...
```

**Check 2: Is job status 'Running'?**
- Only 'Running' jobs change to 'Overrunning'
- 'Paused' jobs won't change until resumed

**Check 3: Are shots being tracked?**
```dart
// Check logs for:
DEBUG Job ProductName: status=Running, shots=95/100
DEBUG Job ProductName: status=Running, shots=100/100
DEBUG Job ProductName: status=Overrunning, shots=105/100
```

**Check 4: Is mould configured correctly?**
- Mould must have cycle time set
- Mould must have cavities set (default = 1)
- Job must have mouldId assigned

### Issue: Shots not incrementing past target

**Solution:** This is now fixed! Shots will continue past target.

**Verify:**
- Check LiveProgressService is tracking 'Overrunning' jobs
- Look for: `where((j) => j['status'] == 'Running' || j['status'] == 'Overrunning')`

---

## 📝 Files Modified

1. **lib/services/live_progress_service.dart**
   - Removed shot clamping
   - Changed auto-finish to auto-overrun
   - Track both Running and Overrunning jobs

2. **lib/screens/daily_input_screen.dart**
   - Check target on manual input
   - Change to Overrunning if needed
   - Debug logging

3. **lib/screens/manage_jobs_screen.dart**
   - Show Overrunning in red
   - Final shot count dialog
   - Archive to Firestore
   - Debug logging

4. **lib/services/sync_service.dart**
   - pushFinishedJob() method
   - Date-organized archiving

---

## ✅ Verification Checklist

After installing the new build, verify:

- [ ] Jobs automatically change to red "Overrunning" when target reached
- [ ] Shots continue incrementing past target
- [ ] Live progress updates every 5 seconds
- [ ] Manual input also triggers Overrunning status
- [ ] "Finish Job" button shows for Overrunning jobs
- [ ] Final shot count dialog appears when finishing
- [ ] Jobs are archived to finishedJobs/{year}/{month}/{day}
- [ ] Active jobs list stays clean
- [ ] Debug logs show status changes

---

## 🚀 Next Build

**Build #93** will include:
- ✅ Automatic overrunning via live progress
- ✅ Manual overrunning via daily input
- ✅ Debug logging for troubleshooting
- ✅ Complete archiving system

**Install the new build and test with a small target (10 shots) for quick verification.**

---

*Document created: November 10, 2024*  
*Overrunning status now works automatically with live progress tracking*
