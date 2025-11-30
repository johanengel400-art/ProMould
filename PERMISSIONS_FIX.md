# User Permissions System - Bug Fixes

## Issues Fixed

### 1. ❌ User Permissions Screen Not Showing in Portrait Mode
**Problem**: The screen used a fixed `Row` layout that only worked in landscape mode.

**Solution**: Added responsive layout that switches between Column (portrait) and Row (landscape):
```dart
final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

body: isPortrait
    ? Column(children: [...])  // Portrait: vertical layout
    : Row(children: [...])      // Landscape: horizontal layout
```

### 2. ❌ Custom Permissions Not Working Correctly
**Problem**: When a user had custom permissions set, the system would return `false` for any permission not explicitly in their custom permissions map, even if their level should grant access by default.

**Original Logic**:
```dart
if (user['permissions'] != null) {
  final permissions = Map<String, bool>.from(user['permissions'] as Map);
  return permissions[permission] ?? false;  // ❌ Returns false if not in map
}
```

**Fixed Logic**:
```dart
// Get default permissions for this level
final defaults = UserPermissions.getDefaultPermissions(widget.level);

if (user['permissions'] != null) {
  final permissions = Map<String, bool>.from(user['permissions'] as Map);
  // If permission is explicitly set, use that value
  // Otherwise fall back to default for this level
  return permissions.containsKey(permission) 
      ? permissions[permission]! 
      : (defaults[permission] ?? false);  // ✅ Falls back to defaults
}
```

### 3. ❌ Menu Order Mixed Up
**Problem**: The menu structure was reorganized incorrectly, mixing operator, setter, and manager items.

**Solution**: Restored original menu structure with proper level-based sections:
- **Operator (Level 1)**: Dashboard, Report Issue
- **Setter (Level 3)**: Dashboard, Mould Changes, Checklists, Inspections, Tasks, Issues
- **Manager (Level 4+)**: All setter items + Timeline, Inputs, Production Sheet, Management section
- **Admin (Level 4+)**: All manager items + User Management, User Permissions, Settings

### 4. ✅ Permission Checks Added Strategically
Only critical management features require explicit permission checks:
- `dashboard` - Can be disabled for any user
- `machines` - Manager feature
- `jobs` - Manager feature
- `mouldChangeChecklist` - Setter/Manager feature
- `mouldChangeHistory` - Setter/Manager feature
- `reports` - Manager feature
- `userManagement` - Admin feature
- `userPermissions` - Admin feature
- `settings` - Admin feature

Other features remain accessible based on user level alone (no custom override needed).

## How It Works Now

### Permission Check Flow
1. Check if user has custom permissions set
2. If yes, check if specific permission is in their custom map
   - If in map: use that value (true/false)
   - If not in map: fall back to default for their level
3. If no custom permissions: use defaults for their level

### Example Scenarios

**Scenario 1: Manager with no custom permissions**
- Level: 4
- Custom permissions: None
- Result: Gets all default level 4 permissions (machines, jobs, reports, etc.)

**Scenario 2: Manager with custom permissions (machines=false)**
- Level: 4
- Custom permissions: `{machines: false}`
- Result: 
  - `machines`: false (custom override)
  - `jobs`: true (default for level 4)
  - `reports`: true (default for level 4)
  - All other permissions: defaults for level 4

**Scenario 3: Setter with custom permissions (dashboard=false)**
- Level: 3
- Custom permissions: `{dashboard: false}`
- Result:
  - `dashboard`: false (custom override)
  - `mouldChangeChecklist`: true (default for level 3)
  - `mouldChangeHistory`: true (default for level 3)
  - All other permissions: defaults for level 3

## Files Modified
1. `lib/screens/user_permissions_screen.dart` - Added responsive layout
2. `lib/screens/role_router.dart` - Fixed permission check logic and restored menu order

## Testing Checklist
- [x] Portrait mode layout works correctly
- [x] Landscape mode layout works correctly
- [x] Permission fallback logic works
- [x] Menu order restored to original structure
- [ ] Test with operator user (level 1)
- [ ] Test with setter user (level 3)
- [ ] Test with manager user (level 4)
- [ ] Test custom permissions override defaults
- [ ] Test permissions persist across app restarts
