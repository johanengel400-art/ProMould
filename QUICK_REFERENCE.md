# ProMould Overrun Features - Quick Reference

## For Operators

### When a Job Overruns
1. **Visual Indicators:**
   - Job card turns RED
   - Warning icon appears
   - "+X shots" badge shows extra shots

2. **What to Do:**
   - Monitor the job
   - When ready to finish, click "Finish" button
   - Enter final shot count in dialog
   - Confirm to complete

### Finishing a Job
```
Manage Jobs → Find Job → Finish Button → Enter Final Shots → Confirm
```

---

## For Supervisors

### Check Overrunning Jobs
- **Dashboard:** Look for red "Active Jobs" card
- **Alerts Panel:** Shows count of overrunning jobs
- **Manage Jobs:** See all jobs with status badges

### View Finished Jobs
```
Menu → Finished Jobs → Select Date → Review
```

**Features:**
- Search by product or machine
- Filter to show only overruns
- Sort by date, product, or overrun amount
- View summary statistics

### Review Analytics
```
Menu → Job Analytics → Select Date Range → Review Metrics
```

**Key Metrics:**
- Overrun rate percentage
- Total extra shots produced
- Overruns by machine
- Overruns by product
- Daily trends
- Worst offenders

---

## Status Colors

| Status | Color | Meaning |
|--------|-------|---------|
| Running | 🟢 Green | Normal operation |
| Overrunning | 🔴 Red | Exceeded target |
| Paused | 🟡 Yellow | Temporarily stopped |
| Queued | ⚪ Gray | Waiting to start |
| Finished | 🔵 Blue | Completed & archived |

---

## Notification Levels

| Level | Duration | Frequency | Action |
|-------|----------|-----------|--------|
| ⚡ MODERATE | 5+ min | Every 20 min | Review job |
| ⚠️ HIGH | 15+ min | Every 15 min | Take action |
| 🚨 CRITICAL | 30+ min | Every 10 min | Urgent! |

---

## Common Tasks

### Find a Specific Finished Job
1. Go to Finished Jobs screen
2. Select the date it was finished
3. Use search bar to find by product or machine
4. Click job card to view details

### Check Machine Overrun History
1. Go to Job Analytics
2. Select date range
3. Scroll to "Overruns by Machine"
4. Find your machine in the list

### See Today's Overrun Rate
1. Go to Job Analytics
2. Set date range to today only
3. Check "Overrun Rate" card at top

### Export Job Data
*Coming soon - currently view only*

---

## Troubleshooting

### Job Won't Finish
- Ensure you're entering a valid final shot count
- Final count must be ≥ current shots
- Check you have permission (Level 2+)

### Can't Find Finished Job
- Verify the correct date is selected
- Check if search filter is active
- Try clearing filters and searching again

### Notifications Not Appearing
- Check notification permissions
- Verify job is actually overrunning
- Check notification settings

---

## Quick Stats Formulas

**Overrun Percentage:**
```
((Shots Completed - Target Shots) / Target Shots) × 100
```

**Overrun Rate:**
```
(Overrun Jobs / Total Jobs) × 100
```

**Extra Shots:**
```
Shots Completed - Target Shots
```

---

## Keyboard Shortcuts

*Currently not implemented - future enhancement*

---

## Tips & Best Practices

### For Operators
- ✅ Finish jobs promptly when target reached
- ✅ Enter accurate final shot counts
- ✅ Monitor overrun notifications
- ❌ Don't ignore overrun alerts
- ❌ Don't let jobs overrun excessively

### For Supervisors
- ✅ Review analytics weekly
- ✅ Identify patterns in overruns
- ✅ Address problematic machines/products
- ✅ Train operators on proper finishing
- ❌ Don't ignore high overrun rates

### For Managers
- ✅ Set overrun targets/goals
- ✅ Track improvement over time
- ✅ Correlate overruns with costs
- ✅ Reward low overrun rates
- ❌ Don't punish without investigation

---

## Need Help?

1. **Check Documentation:** See OVERRUN_FEATURES.md
2. **Ask Supervisor:** They can help with procedures
3. **Contact IT:** For technical issues
4. **Training:** Request refresher training if needed

---

**Version:** 1.0.0  
**Last Updated:** November 10, 2024
