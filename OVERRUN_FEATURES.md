# Job Overrunning & Finished Jobs Features

## Overview

This document describes the comprehensive job overrunning and finished jobs features implemented in ProMould. These features provide complete visibility into job lifecycle, from running through overrunning to archival, with smart notifications and analytics.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Architecture](#architecture)
3. [Features](#features)
4. [User Interface](#user-interface)
5. [Services](#services)
6. [Utilities & Widgets](#utilities--widgets)
7. [Usage Guide](#usage-guide)
8. [Testing](#testing)

---

## Core Concepts

### Job Lifecycle

```
Queued → Running → Overrunning → Finished (Archived)
                ↓
              Paused
```

**Status Definitions:**
- **Queued**: Job is waiting to start
- **Running**: Job is actively running, shots < target
- **Overrunning**: Job has exceeded target shots but continues running
- **Paused**: Job temporarily stopped (can resume)
- **Finished**: Job completed and archived to Firebase

### Key Principles

1. **No Auto-Finish**: Jobs never automatically finish when reaching target
2. **Continuous Tracking**: Live progress continues indefinitely for Running/Overrunning jobs
3. **Manual Completion**: Operators manually finish jobs with final shot count
4. **Date-Organized Archival**: Finished jobs stored in Firebase by year/month/day
5. **Smart Notifications**: Escalating alerts for overrunning jobs

---

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Live Progress Service                     │
│  • Updates shots every 5 seconds                            │
│  • Changes status to Overrunning when target reached        │
│  • Never auto-finishes jobs                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────────┐
│                 Overrun Notification Service                 │
│  • Monitors overrunning jobs every 2 minutes                │
│  • Sends escalating notifications (5min, 15min, 30min)      │
│  • Tracks notification history                              │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────────┐
│                      User Interface                          │
│  • Dashboard: Shows Running + Overrunning counts            │
│  • Manage Jobs: Finish button with final shot dialog       │
│  • Analytics: Overrun metrics and trends                    │
│  • Finished Jobs: Date-filtered archive viewer             │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Archival                         │
│  finishedJobs/{year}/{month}/{day}/jobs/{jobId}            │
│  • Organized by completion date                             │
│  • Includes all job data + overrun metrics                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

### 1. Job Overrunning Detection

**Automatic Status Change:**
- When `shotsCompleted >= targetShots`, status changes from `Running` to `Overrunning`
- `overrunStartTime` timestamp recorded
- Live progress continues tracking indefinitely

**Visual Indicators:**
- Red color scheme for overrunning jobs
- Pulsing indicator animation
- Overrun badge showing extra shots and percentage
- Progress bar with overrun visualization

### 2. Finished Jobs Management

**Manual Completion:**
- Operators click "Finish" button on job
- Dialog prompts for final shot count
- Job archived to Firebase with completion data
- Machine freed for next queued job

**Date-Organized Storage:**
```
finishedJobs/
  2024/
    11/
      10/
        jobs/
          {jobId}/
            - productName
            - machineId
            - shotsCompleted
            - targetShots
            - startTime
            - finishedDate
            - overrunStartTime (if applicable)
            - ... all job data
```

### 3. Finished Jobs Viewer

**Features:**
- Date picker for selecting viewing date
- Search by product name or machine ID
- Filter to show only overrun jobs
- Sort by date, product, or overrun amount
- Summary statistics footer
- Visual overrun indicators

**UI Components:**
- Date selector with calendar picker
- Search bar with real-time filtering
- Filter chips for quick access
- Sort dropdown with ascending/descending toggle
- Job cards with overrun badges
- Summary panel with totals

### 4. Job Analytics Dashboard

**Metrics Tracked:**
- Total jobs completed
- Overrun job count and percentage
- Total shots vs target shots
- Average overrun percentage
- Overruns by machine
- Overruns by product
- Daily trend analysis
- Worst offenders list

**Visualizations:**
- Overview stat cards
- Overrun rate gauge with color coding
- Horizontal bar charts for breakdowns
- Daily trend table
- Worst offenders cards

### 5. Smart Notifications

**Escalation Levels:**

| Level | Duration | Interval | Action |
|-------|----------|----------|--------|
| MODERATE | 5+ min | Every 20 min | Initial alert |
| HIGH | 15+ min | Every 15 min | Escalated alert |
| CRITICAL | 30+ min | Every 10 min | Urgent action required |

**Notification Content:**
- Job product name and machine
- Overrun duration
- Extra shots count and percentage
- Severity level indicator
- Action recommendation

---

## User Interface

### Dashboard Updates

**Active Jobs Card:**
- Shows count of Running + Overrunning jobs
- Red color when overrunning jobs present
- Subtitle shows overrunning count

**Alerts Panel:**
- New alert for overrunning jobs
- Shows count and "Exceeded target shots" message
- Red warning icon

### Manage Jobs Screen

**Job Cards:**
- Status badge with appropriate color
- Overrun badge when applicable
- Overrun progress bar
- Finish button for Running/Overrunning jobs

**Finish Dialog:**
- Current shots displayed
- Input for final shot count
- Validation (must be >= current shots)
- Confirmation with summary

### Machine Detail Screen

**Updates:**
- Shows Running and Overrunning jobs
- Overrun indicators on job cards
- Duration display for overrunning jobs

### Planning Screen

**Updates:**
- Counts include overrunning jobs
- Visual indicators on machine cards
- Accurate time estimates

---

## Services

### JobStatus Utility (`lib/utils/job_status.dart`)

**Purpose:** Centralized job status management

**Key Methods:**
```dart
// Status checks
JobStatus.isActivelyRunning(status)  // Running or Overrunning
JobStatus.isActive(status)           // Running, Overrunning, or Paused
JobStatus.shouldTrackProgress(status) // Should live progress track?

// Visual helpers
JobStatus.getColor(status)           // Status color
JobStatus.getIcon(status)            // Status icon
JobStatus.getDisplayName(status)     // Human-readable name

// Overrun calculations
JobStatus.getOverrunShots(completed, target)
JobStatus.getOverrunPercentage(completed, target)
JobStatus.getOverrunDuration(job)
JobStatus.formatOverrunDuration(minutes)
JobStatus.isOverrunning(job)
```

### LiveProgressService (`lib/services/live_progress_service.dart`)

**Updates:**
- Tracks both Running and Overrunning jobs
- Changes status to Overrunning when target reached
- Never auto-finishes jobs
- Continues tracking indefinitely

**Configuration:**
- Update interval: 5 seconds
- Firebase sync: Every 10 shots

### OverrunNotificationService (`lib/services/overrun_notification_service.dart`)

**Features:**
- Monitors overrunning jobs every 2 minutes
- Escalating notification logic
- Tracks notification history per job
- Provides overrun summary for dashboard

**Methods:**
```dart
OverrunNotificationService.start()
OverrunNotificationService.stop()
OverrunNotificationService.checkJobImmediately(job)
OverrunNotificationService.getOverrunSummary()
OverrunNotificationService.resetJobTracking(jobId)
OverrunNotificationService.getJobNotificationInfo(jobId)
```

### SyncService Updates (`lib/services/sync_service.dart`)

**New Method:**
```dart
SyncService.pushFinishedJob(jobId, jobData)
```

Archives finished job to Firebase in date-organized structure.

---

## Utilities & Widgets

### Reusable Widgets (`lib/widgets/overrun_indicator.dart`)

**OverrunBadge:**
- Shows overrun shots and percentage
- Compact and full modes
- Red color scheme

**OverrunPulseIndicator:**
- Animated pulsing dot
- Only shows for overrunning jobs
- Configurable size

**OverrunProgressBar:**
- Visual progress with overrun section
- Color gradient (green → yellow → red)
- Shows shots completed vs target
- Optional percentage display

**JobStatusBadge:**
- Status indicator with icon and color
- Compact and full modes
- Uses JobStatus utility

**OverrunDurationDisplay:**
- Shows how long job has been overrunning
- Formatted duration (e.g., "2h 15m")
- Timer icon with red color

---

## Usage Guide

### For Operators

**When a Job Reaches Target:**
1. Job status automatically changes to "Overrunning"
2. Visual indicators appear (red color, warning icon)
3. Continue monitoring the job
4. When ready to finish:
   - Click "Finish" button
   - Enter final shot count
   - Confirm completion

**Notifications:**
- You'll receive alerts if job overruns too long
- Check the job and decide whether to finish or continue

### For Supervisors/Managers

**Monitoring Overruns:**
1. Dashboard shows overrunning job count in alerts
2. Active Jobs card turns red when overruns present
3. Click through to Manage Jobs for details

**Viewing Finished Jobs:**
1. Navigate to Finished Jobs screen
2. Select date to view
3. Use search to find specific jobs
4. Filter to show only overruns
5. Review summary statistics

**Analytics:**
1. Open Job Analytics screen
2. Select date range
3. Review overrun rate and trends
4. Identify problematic machines/products
5. Take corrective action

### For Administrators

**Configuration:**
- Notification thresholds in `overrun_notification_service.dart`
- Live progress update interval in `live_progress_service.dart`
- Firebase archival structure in `sync_service.dart`

**Monitoring:**
- Check logs for service status
- Review notification history
- Monitor Firebase storage usage

---

## Testing

### Manual Testing Checklist

**Job Overrunning:**
- [ ] Job changes to Overrunning when target reached
- [ ] Live progress continues after target
- [ ] Overrun indicators appear on all screens
- [ ] Dashboard shows overrunning count
- [ ] Alerts panel shows overrun alert

**Finishing Jobs:**
- [ ] Finish button appears for Running/Overrunning jobs
- [ ] Dialog shows current shot count
- [ ] Can enter final shot count
- [ ] Validation prevents invalid counts
- [ ] Job archived to Firebase correctly
- [ ] Next queued job starts automatically

**Finished Jobs Viewer:**
- [ ] Date picker works correctly
- [ ] Jobs load for selected date
- [ ] Search filters jobs correctly
- [ ] Overrun filter works
- [ ] Sort options work
- [ ] Summary statistics accurate
- [ ] Empty state shows when no jobs

**Analytics:**
- [ ] Date range picker works
- [ ] Metrics calculate correctly
- [ ] Charts display properly
- [ ] Machine breakdown accurate
- [ ] Product breakdown accurate
- [ ] Daily trend shows correctly
- [ ] Worst offenders list accurate

**Notifications:**
- [ ] Notifications sent at correct intervals
- [ ] Escalation levels work
- [ ] Notification content accurate
- [ ] Tracking prevents spam
- [ ] Reset works when job finishes

### Integration Testing

**Scenario 1: Normal Job Completion**
1. Start a job
2. Let it reach target
3. Verify status changes to Overrunning
4. Finish job immediately
5. Verify archived correctly

**Scenario 2: Extended Overrun**
1. Start a job
2. Let it reach target
3. Wait 5+ minutes
4. Verify MODERATE notification
5. Wait 15+ minutes
6. Verify HIGH notification
7. Wait 30+ minutes
8. Verify CRITICAL notification
9. Finish job
10. Verify notifications stop

**Scenario 3: Multiple Overruns**
1. Start multiple jobs
2. Let all reach target
3. Verify dashboard shows correct count
4. Verify alerts panel shows total
5. Finish jobs one by one
6. Verify counts update correctly

**Scenario 4: Analytics Accuracy**
1. Finish several jobs (some overrun, some not)
2. Open analytics
3. Verify all metrics match actual data
4. Change date range
5. Verify metrics update correctly

---

## File Structure

```
lib/
├── utils/
│   └── job_status.dart                    # Centralized status management
├── widgets/
│   └── overrun_indicator.dart             # Reusable overrun widgets
├── services/
│   ├── live_progress_service.dart         # Updated for overrunning
│   ├── overrun_notification_service.dart  # Smart notifications
│   └── sync_service.dart                  # Updated with pushFinishedJob
├── screens/
│   ├── dashboard_screen_v2.dart           # Updated with overrun counts
│   ├── manage_jobs_screen.dart            # Updated with finish button
│   ├── machine_detail_screen.dart         # Updated with overrun indicators
│   ├── planning_screen.dart               # Updated with overrun support
│   ├── finished_jobs_screen.dart          # NEW: Archive viewer
│   └── job_analytics_screen.dart          # NEW: Analytics dashboard
└── main.dart                              # Updated to start services
```

---

## Future Enhancements

### Potential Improvements

1. **Predictive Warnings:**
   - ML model to predict likely overruns
   - Early warnings before target reached
   - Based on historical patterns

2. **Automated Actions:**
   - Auto-pause jobs at certain overrun threshold
   - Auto-notify specific users for specific machines
   - Integration with machine controls

3. **Advanced Analytics:**
   - Correlation analysis (time of day, operator, etc.)
   - Cost impact calculations
   - Efficiency scoring

4. **Export & Reporting:**
   - PDF report generation
   - CSV export of finished jobs
   - Scheduled email reports

5. **Mobile Notifications:**
   - Push notifications to mobile devices
   - In-app notification center
   - Notification preferences per user

6. **Real-time Dashboard:**
   - Live updating charts
   - WebSocket integration
   - Multi-user collaboration

---

## Support

For questions or issues:
1. Check this documentation
2. Review code comments
3. Check logs in LogService
4. Contact development team

---

## Changelog

### Version 1.0.0 (Current)
- Initial implementation of overrunning features
- Finished jobs viewer with filtering
- Job analytics dashboard
- Smart notification system
- Reusable overrun widgets
- Centralized status management
- Complete integration across all screens

---

**Last Updated:** November 10, 2024
**Author:** ProMould Development Team
