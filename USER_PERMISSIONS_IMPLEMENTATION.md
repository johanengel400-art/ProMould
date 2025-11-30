# User Permissions System Implementation

## Overview
Implemented a granular user permissions system that allows admins to control which pages/features each individual user can access, beyond their default role-based permissions.

## Components Created

### 1. `lib/utils/user_permissions.dart`
Central utility class that defines:
- **Page constants**: All available pages/features (dashboard, machines, jobs, etc.)
- **Default permissions by level**: What each user level (1-4) can access by default
- **Display names**: User-friendly names for each permission

### 2. `lib/screens/user_permissions_screen.dart`
Admin interface for managing user permissions:
- **Two-panel layout**:
  - Left: List of all users
  - Right: Permission toggles for selected user
- **Features**:
  - Save custom permissions to user object
  - Reset to defaults based on user level
  - Real-time permission toggling
- **Storage**: Permissions stored in `user.permissions` Map<String, bool> in Hive

### 3. `lib/screens/role_router.dart` (Updated)
Integrated permission checks into navigation drawer:
- Added `_hasPermission(String permission)` helper method
- Checks custom permissions first, falls back to defaults
- Updated all menu items to check permissions before rendering
- Added "User Permissions" menu item for admins

## How It Works

### Permission Check Flow
1. When rendering a menu item, `_hasPermission()` is called
2. Loads user object from Hive
3. If user has custom permissions set, uses those
4. Otherwise, falls back to default permissions for their level
5. Returns true/false to show/hide the menu item

### Default Permissions by Level
- **Level 1 (Operator)**: Dashboard only
- **Level 2 (Material Handler)**: Dashboard only (reserved for future use)
- **Level 3 (Setter)**: Dashboard, Mould Change Checklist, Mould Change History
- **Level 4+ (Manager/Admin)**: All features

### Customization
Admins can:
1. Navigate to "User Permissions" in the admin menu
2. Select a user from the list
3. Toggle individual permissions on/off
4. Save changes (persists to Hive)
5. Reset to defaults if needed

## Key Features
- **Granular control**: Individual permissions per user
- **Fallback system**: Defaults based on user level if no custom permissions
- **Persistent**: Permissions stored in Hive, survive app restarts
- **Admin-only**: Only level 4+ users can access User Permissions screen
- **Real-time**: Changes take effect immediately (user may need to reopen drawer)

## Testing Checklist
- [ ] Verify default permissions work for each level (1-4)
- [ ] Test custom permissions override defaults
- [ ] Ensure permissions persist across app restarts
- [ ] Verify only admins can access User Permissions screen
- [ ] Test reset to defaults functionality
- [ ] Check that menu items appear/disappear based on permissions

## Files Modified
1. `lib/utils/user_permissions.dart` (CREATED)
2. `lib/screens/user_permissions_screen.dart` (CREATED)
3. `lib/screens/role_router.dart` (UPDATED)
   - Added Hive import
   - Added UserPermissions import
   - Added UserPermissionsScreen import
   - Added `_hasPermission()` method
   - Updated all menu items with permission checks
   - Added "User Permissions" menu item

## Usage Example

### For Admins
```dart
// Navigate to User Permissions screen
// Select user "john_doe"
// Toggle "Machines" permission OFF
// Save changes
// User "john_doe" will no longer see "Machines" in their menu
```

### For Developers
```dart
// Check if user has permission
if (_hasPermission(UserPermissions.machines)) {
  // Show machines menu item
}

// Get default permissions for a level
final defaults = UserPermissions.getDefaultPermissions(4);
// Returns: {dashboard: true, machines: true, jobs: true, ...}

// Get display name for a permission
final name = UserPermissions.getDisplayName('machines');
// Returns: "Machines"
```

## Future Enhancements
- Add permission groups (e.g., "Production", "Management", "Admin")
- Add bulk permission editing (apply to multiple users)
- Add permission templates (save/load permission sets)
- Add audit log (track who changed what permissions when)
- Add permission inheritance (e.g., "Manager" role automatically gets certain permissions)
