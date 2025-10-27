# Dashboard V2 Styling Guide

## Progress Summary

### ✅ Completed Screens (11/19)
1. **dashboard_screen_v2.dart** - Already modern
2. **timeline_screen_v2.dart** - Already modern
3. **quality_control_screen.dart** - Already modern
4. **job_queue_manager_screen.dart** - Already modern
5. **my_tasks_screen.dart** - Already modern
6. **mould_change_scheduler_screen.dart** - Already modern
7. **issues_screen_v2.dart** - ✅ **NEWLY REBUILT** with full CRUD
8. **daily_input_screen.dart** - ✅ **NEWLY STYLED**
9. **downtime_screen.dart** - ✅ **NEWLY STYLED**
10. **manage_floors_screen.dart** - ✅ **NEWLY STYLED**

### ⏳ Remaining Screens (8/19)
1. **machine_detail_screen.dart** (250 lines)
2. **manage_jobs_screen.dart** (307 lines)
3. **manage_machines_screen.dart** (146 lines)
4. **manage_moulds_screen.dart** (150 lines)
5. **manage_users_screen.dart** (107 lines)
6. **mould_changes_screen.dart** (249 lines)
7. **oee_screen.dart** (165 lines)
8. **paperwork_screen.dart** (568 lines)
9. **planning_screen.dart** (564 lines)
10. **settings_screen.dart** (136 lines)

---

## Styling Pattern

### 1. Replace Standard Scaffold

**Before:**
```dart
return Scaffold(
  appBar: AppBar(title: const Text('Screen Title')),
  body: ListView(...),
);
```

**After:**
```dart
return Scaffold(
  backgroundColor: const Color(0xFF0A0E1A),
  body: CustomScrollView(
    slivers: [
      SliverAppBar(
        expandedHeight: 120,
        floating: false,
        pinned: true,
        backgroundColor: const Color(0xFF0F1419),
        flexibleSpace: FlexibleSpaceBar(
          title: const Text('Screen Title'),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CC9F0).withOpacity(0.3),
                  const Color(0xFF0F1419),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      // Content goes here as SliverPadding/SliverList/SliverToBoxAdapter
    ],
  ),
);
```

### 2. Update Card Styling

**Before:**
```dart
Card(
  child: ListTile(
    title: Text('Item'),
    subtitle: Text('Details'),
  ),
)
```

**After:**
```dart
Card(
  margin: const EdgeInsets.only(bottom: 12),
  color: const Color(0xFF0F1419),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: Colors.white12),
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.all(16),
    leading: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CC9F0).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.icon_name, color: const Color(0xFF4CC9F0)),
    ),
    title: Text('Item', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    subtitle: Text('Details', style: const TextStyle(color: Colors.white70)),
  ),
)
```

### 3. Update FloatingActionButton

**Before:**
```dart
FloatingActionButton(
  onPressed: () => _action(),
  child: const Icon(Icons.add),
)
```

**After:**
```dart
FloatingActionButton.extended(
  onPressed: () => _action(),
  backgroundColor: const Color(0xFF4CC9F0),
  icon: const Icon(Icons.add),
  label: const Text('Action Label'),
)
```

### 4. Update TextFields (in dialogs/forms)

**Before:**
```dart
TextField(
  controller: ctrl,
  decoration: const InputDecoration(labelText: 'Label'),
)
```

**After:**
```dart
TextField(
  controller: ctrl,
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
    labelText: 'Label',
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF4CC9F0)),
    ),
  ),
)
```

### 5. Update Dialogs

**Before:**
```dart
AlertDialog(
  title: Text('Title'),
  content: Column(...),
  actions: [...],
)
```

**After:**
```dart
AlertDialog(
  backgroundColor: const Color(0xFF0F1419),
  title: const Text('Title', style: TextStyle(color: Colors.white)),
  content: Column(...),
  actions: [...],
)
```

---

## Color Palette Reference

```dart
// Backgrounds
const backgroundColor = Color(0xFF0A0E1A);
const cardBackground = Color(0xFF0F1419);

// Primary Colors
const primaryCyan = Color(0xFF4CC9F0);
const primaryGreen = Color(0xFF06D6A0);
const primaryYellow = Color(0xFFFFD166);
const primaryOrange = Color(0xFFFF8C42);
const primaryRed = Color(0xFFEF476F);

// Text Colors
const textWhite = Colors.white;
const textWhite70 = Colors.white70;
const textWhite38 = Colors.white38;

// Status Colors
const statusRunning = Color(0xFF4CC9F0);   // Cyan
const statusIdle = Color(0xFFFFD166);      // Yellow
const statusBreakdown = Color(0xFFEF476F); // Red
const statusCompleted = Color(0xFF06D6A0); // Green

// Priority Colors
const priorityLow = Color(0xFF06D6A0);      // Green
const priorityMedium = Color(0xFFFFD166);   // Yellow
const priorityHigh = Color(0xFFFF8C42);     // Orange
const priorityCritical = Color(0xFFEF476F); // Red
```

---

## Screen-Specific Gradient Colors

Choose gradient color based on screen purpose:

- **Management screens** (machines, jobs, moulds, users): `Color(0xFF4CC9F0)` (Cyan)
- **Quality/Issues screens**: `Color(0xFFEF476F)` (Red)
- **Planning/Timeline screens**: `Color(0xFF06D6A0)` (Green)
- **Reports/Analytics screens**: `Color(0xFF9D4EDD)` (Purple)
- **Settings screens**: `Color(0xFF6C757D)` (Gray)

---

## Step-by-Step Process for Each Screen

### 1. Backup (optional)
```bash
cp lib/screens/screen_name.dart lib/screens/screen_name.dart.backup
```

### 2. Update Scaffold Structure
- Change `Scaffold` to use `backgroundColor: const Color(0xFF0A0E1A)`
- Replace `appBar: AppBar(...)` with `body: CustomScrollView(slivers: [SliverAppBar(...), ...])`
- Convert body content to Sliver widgets

### 3. Update Cards
- Add `color: const Color(0xFF0F1419)`
- Add `shape: RoundedRectangleBorder(...)` with rounded corners and border
- Update `ListTile` with `contentPadding` and styled `leading` icon container

### 4. Update Text Styles
- Titles: `TextStyle(color: Colors.white, fontWeight: FontWeight.bold)`
- Subtitles: `TextStyle(color: Colors.white70)`
- Labels: `TextStyle(color: Colors.white38)`

### 5. Update Buttons
- FAB: Use `FloatingActionButton.extended` with background color
- Dialogs: Add `backgroundColor: const Color(0xFF0F1419)`

### 6. Test
- Verify no syntax errors
- Check visual consistency with Dashboard V2

---

## Example: Complete Transformation

See `lib/screens/manage_floors_screen.dart` for a complete before/after example.

**Key changes:**
1. ✅ Dark background (`0xFF0A0E1A`)
2. ✅ Gradient SliverAppBar
3. ✅ Styled cards with rounded corners and borders
4. ✅ Icon containers with colored backgrounds
5. ✅ Extended FAB with label
6. ✅ Consistent text colors

---

## Quick Reference: ListView to SliverList Conversion

**Before:**
```dart
body: ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => Card(...),
)
```

**After:**
```dart
body: CustomScrollView(
  slivers: [
    SliverAppBar(...),
    SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Card(...),
          childCount: items.length,
        ),
      ),
    ),
  ],
)
```

---

## Estimated Time per Screen

- **Simple screens** (manage_floors, manage_users, settings): 15-20 minutes
- **Medium screens** (manage_machines, manage_moulds, oee): 25-35 minutes
- **Complex screens** (manage_jobs, planning, paperwork): 45-60 minutes

**Total estimated time for 8 remaining screens: 4-6 hours**

---

## Testing Checklist

After styling each screen:
- [ ] No syntax errors
- [ ] Dark background visible
- [ ] Gradient AppBar displays correctly
- [ ] Cards have rounded corners and borders
- [ ] Icons have colored background containers
- [ ] Text is readable (white/white70)
- [ ] FAB has label and color
- [ ] Dialogs have dark background
- [ ] Consistent with Dashboard V2 design

---

## Notes

- All screens should maintain their existing functionality
- Only visual styling changes are needed
- Keep existing business logic intact
- Test each screen after styling to ensure no regressions
