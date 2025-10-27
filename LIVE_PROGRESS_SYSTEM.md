# Live Progress System - Real-Time Shot Counting

## Overview

The Live Progress System provides real-time, continuous updates to job progress based on mould cycle times. Progress bars and shot counts update automatically every few seconds, creating a "live factory floor" experience where machines appear to be actively working.

## How It Works

### 1. Automatic Shot Estimation

When a job is running, the system calculates estimated shots based on:
- **Cycle Time**: From the mould configuration (e.g., 30 seconds per shot)
- **Elapsed Time**: Time since job started or last manual update
- **Formula**: `estimated_shots = elapsed_seconds / cycle_time`

### 2. Manual Input Override

When operators input actual shot counts via the Daily Input screen:
- The system records the actual count as a new baseline
- Timestamps the manual update
- Continues counting from this corrected baseline
- This allows for periodic corrections while maintaining live updates

### 3. Continuous Updates

**Background Service** (`LiveProgressService`):
- Updates every 5 seconds in the background
- Calculates estimated shots for all running jobs
- Saves to database periodically (every 10 shots to reduce Firebase writes)
- Automatically handles job completion and queue progression

**UI Updates**:
- Dashboard: Updates every 2 seconds
- Planning Screen: Updates every 2 seconds
- Timeline Screen: Updates every 3 seconds

## Architecture

### Core Service: `live_progress_service.dart`

```dart
class LiveProgressService {
  // Start the background timer
  static void start()
  
  // Stop the background timer
  static void stop()
  
  // Record manual input and reset baseline
  static Future<void> recordManualInput(String jobId, int actualShots)
  
  // Get current estimated shots for display
  static int getEstimatedShots(Map job, Box mouldsBox)
}
```

### Data Structure

Jobs now include additional fields for tracking:

```dart
{
  'id': String,
  'status': String,
  'startTime': String (ISO8601),
  'shotsCompleted': int,              // Current count (auto or manual)
  'targetShots': int,
  'mouldId': String,
  
  // New fields for live progress:
  'lastManualUpdate': String?,        // Timestamp of last manual input
  'manualShotsCompleted': int?,       // Actual count from last manual input
}
```

### Calculation Logic

**For Running Jobs:**

1. **Determine Reference Point:**
   - If manual update exists: Use `lastManualUpdate` timestamp and `manualShotsCompleted`
   - Otherwise: Use job `startTime` with 0 shots

2. **Calculate Elapsed Time:**
   ```dart
   elapsed_seconds = now - reference_time
   ```

3. **Estimate New Shots:**
   ```dart
   estimated_new_shots = elapsed_seconds / cycle_time
   total_shots = baseline_shots + estimated_new_shots
   ```

4. **Clamp to Target:**
   ```dart
   current_shots = min(total_shots, target_shots)
   ```

**For Queued Jobs:**
- Use stored `shotsCompleted` (no estimation)
- Calculate ETA based on when they'll start

## User Experience

### What Users See

**Dashboard:**
- Progress bars animate smoothly
- Shot counts increment automatically
- ETAs update dynamically
- Percentage increases in real-time

**Example:**
```
Job: Widget A • 47%
⬛⬛⬛⬛⬛⬜⬜⬜⬜⬜
🕐 ETA Oct 27 16:30 (2h 15m)
```

After 30 seconds (1 cycle):
```
Job: Widget A • 48%
⬛⬛⬛⬛⬛⬜⬜⬜⬜⬜
🕐 ETA Oct 27 16:29 (2h 14m)
```

### Manual Input Flow

1. **Operator checks actual count:** 450 shots
2. **System was estimating:** 465 shots (15 shots ahead)
3. **Operator inputs:** 450 shots via Daily Input
4. **System resets:**
   - `shotsCompleted` = 450
   - `manualShotsCompleted` = 450
   - `lastManualUpdate` = now
5. **Counting continues from 450**

## Benefits

### For Operators
- **Real-time visibility**: See machines working without manual updates
- **Accurate ETAs**: Dynamic completion times based on actual progress
- **Periodic corrections**: Input actual counts to maintain accuracy
- **Reduced data entry**: Only need to input periodically, not constantly

### For Managers
- **Live monitoring**: Dashboard shows real-time factory status
- **Better planning**: Accurate ETAs for scheduling
- **Progress tracking**: See if jobs are on pace or falling behind
- **Automatic updates**: No waiting for operator input to see progress

### For the System
- **Reduced Firebase writes**: Only sync every 10 shots, not every update
- **Automatic job completion**: Jobs finish and queue progresses automatically
- **Self-correcting**: Manual inputs keep estimates accurate
- **Scalable**: Works for any number of machines/jobs

## Configuration

### Update Intervals

**Background Service:**
```dart
Timer.periodic(const Duration(seconds: 5), ...)  // Update data every 5s
```

**UI Refresh:**
```dart
// Dashboard & Planning
Timer.periodic(const Duration(seconds: 2), ...)  // Refresh UI every 2s

// Timeline
Timer.periodic(const Duration(seconds: 3), ...)  // Refresh UI every 3s
```

**Firebase Sync:**
```dart
if (estimatedNewShots % 10 == 0) {
  await SyncService.pushChange(...)  // Sync every 10 shots
}
```

### Customization

To adjust update frequency, modify the timers in:
- `lib/services/live_progress_service.dart` - Background updates
- `lib/screens/dashboard_screen.dart` - Dashboard refresh
- `lib/screens/planning_screen.dart` - Planning refresh
- `lib/screens/timeline_screen.dart` - Timeline refresh

## Technical Details

### Performance Considerations

**Efficient Updates:**
- UI updates use `setState()` on timers, not constant polling
- Background service only processes running jobs
- Firebase syncs are throttled to every 10 shots
- Calculations are simple arithmetic (no heavy processing)

**Memory Usage:**
- Single timer per screen (not per job)
- No data accumulation (calculations are stateless)
- Minimal additional data stored per job

**Battery Impact:**
- Timers are lightweight (2-5 second intervals)
- No GPS, sensors, or heavy operations
- Background service can be stopped if needed

### Edge Cases Handled

1. **Job Completion:**
   - Automatically marks job as finished
   - Starts next queued job
   - Sets machine to idle if no more jobs

2. **Manual Input During Running:**
   - Resets baseline immediately
   - Continues counting from new baseline
   - No data loss or conflicts

3. **App Restart:**
   - Service restarts automatically
   - Uses stored timestamps to calculate correct progress
   - No progress lost

4. **No Mould Assigned:**
   - Falls back to stored `shotsCompleted`
   - No estimation (manual input only)

5. **Negative Remaining:**
   - Clamped to target (never exceeds)
   - Job marked as finished

## Testing Scenarios

### Scenario 1: New Job Start
```
1. Assign job to machine (target: 1000 shots, cycle: 30s)
2. Job starts at 14:00:00
3. At 14:05:00 (5 minutes later):
   - Expected: ~10 shots (300s / 30s)
   - Progress bar: 1%
   - ETA: ~8.3 hours from now
```

### Scenario 2: Manual Correction
```
1. Job running, system estimates 100 shots
2. Operator counts: actually 95 shots
3. Operator inputs 95 via Daily Input
4. System resets to 95 and continues
5. 1 minute later: shows 97 shots (95 + 2)
```

### Scenario 3: Job Completion
```
1. Job at 998/1000 shots
2. After 1 minute (2 cycles): reaches 1000
3. System automatically:
   - Marks job as finished
   - Starts next queued job
   - Updates machine status
```

### Scenario 4: Multiple Machines
```
1. 10 machines running simultaneously
2. Each updates independently
3. Dashboard shows all 10 with live progress
4. Background service handles all in single timer
```

## Troubleshooting

### Progress Not Updating

**Check:**
1. Is `LiveProgressService.start()` called in `main.dart`?
2. Is the job status 'Running'?
3. Is there a valid mould with cycle time?
4. Check console for error messages

**Solution:**
```dart
// Verify service is running
print('Service running: ${LiveProgressService._isRunning}');

// Check job data
final job = jobsBox.get(jobId);
print('Job status: ${job['status']}');
print('Start time: ${job['startTime']}');
print('Mould ID: ${job['mouldId']}');
```

### Progress Too Fast/Slow

**Cause:** Incorrect cycle time in mould configuration

**Solution:**
1. Go to Manage Moulds
2. Edit the mould
3. Adjust cycle time (in seconds)
4. Progress will recalculate automatically

### Manual Input Not Resetting

**Check:**
1. Is `LiveProgressService.recordManualInput()` being called?
2. Check job data for `lastManualUpdate` field

**Solution:**
```dart
// Verify manual input was recorded
final job = jobsBox.get(jobId);
print('Manual shots: ${job['manualShotsCompleted']}');
print('Last update: ${job['lastManualUpdate']}');
```

## Future Enhancements

### Potential Improvements

1. **Adaptive Cycle Times:**
   - Learn actual cycle times from manual inputs
   - Adjust estimates based on historical data
   - Account for machine-specific variations

2. **Downtime Detection:**
   - Detect when progress stops (machine breakdown)
   - Pause estimation during downtime
   - Resume when machine restarts

3. **Efficiency Tracking:**
   - Compare estimated vs actual progress
   - Calculate OEE in real-time
   - Alert on below-target performance

4. **Predictive ETAs:**
   - Use historical data for more accurate ETAs
   - Account for shift changes, breaks
   - Machine learning for better predictions

5. **Real Machine Integration:**
   - Connect to actual machine PLCs
   - Get real shot counts directly
   - Eliminate need for manual input

## API Reference

### LiveProgressService

#### `start()`
Starts the background timer for automatic progress updates.
```dart
LiveProgressService.start();
```

#### `stop()`
Stops the background timer.
```dart
LiveProgressService.stop();
```

#### `recordManualInput(String jobId, int actualShots)`
Records a manual shot count input and resets the baseline.
```dart
await LiveProgressService.recordManualInput('job-123', 450);
```

#### `getEstimatedShots(Map job, Box mouldsBox)`
Calculates and returns the current estimated shot count for a job.
```dart
final shots = LiveProgressService.getEstimatedShots(job, mouldsBox);
```

## Summary

The Live Progress System transforms ProMould from a static data entry system into a dynamic, real-time factory monitoring solution. By automatically estimating progress based on cycle times and allowing periodic manual corrections, it provides the best of both worlds: continuous visibility with maintained accuracy.

**Key Features:**
- ✅ Real-time progress updates
- ✅ Automatic shot counting
- ✅ Manual input override
- ✅ Dynamic ETA calculations
- ✅ Automatic job completion
- ✅ Efficient Firebase syncing
- ✅ Low performance impact

**Result:** A live, breathing dashboard that shows your factory floor in real-time! 🏭⚡
