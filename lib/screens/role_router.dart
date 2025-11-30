// lib/screens/role_router.dart
// v7.2 – Material 3 Navigation Drawer (replaces bottom nav)

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// import all screens
import 'login_screen.dart';
import 'dashboard_screen_v2.dart';
import 'timeline_screen_v2.dart';
import 'daily_input_screen.dart';
import 'issues_screen_v2.dart';
import 'manage_machines_screen.dart';
import 'manage_jobs_screen.dart';
import 'manage_moulds_screen.dart';
import 'manage_floors_screen.dart';
import 'manage_users_screen.dart';
import 'planning_screen.dart';
import 'downtime_screen.dart';
import 'oee_screen.dart';
import 'settings_screen.dart';
import 'mould_change_scheduler_screen.dart';
import 'mould_change_checklist_screen.dart';
import 'mould_change_history_screen.dart';
import 'user_permissions_screen.dart';
import 'job_queue_manager_screen.dart';
import '../utils/user_permissions.dart';
import 'my_tasks_screen.dart';
import 'quality_control_screen.dart';
import 'production_timeline_screen.dart';
import 'operator_qc_screen.dart';
import 'machine_inspection_checklist_screen.dart';
import 'daily_inspection_tracking_screen.dart';
import 'finished_jobs_screen.dart';
import 'job_analytics_screen.dart';
import 'daily_production_sheet_screen.dart';

class RoleRouter extends StatefulWidget {
  final int level;
  final String username;
  const RoleRouter({super.key, required this.level, required this.username});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Widget _activeScreen;
  late String _title;

  @override
  void initState() {
    super.initState();
    _activeScreen =
        DashboardScreenV2(username: widget.username, level: widget.level);
    _title = 'Dashboard';
  }

  void _navigate(String title, Widget screen) {
    setState(() {
      _activeScreen = screen;
      _title = title;
    });
    Navigator.pop(context);
  }

  bool _hasPermission(String permission) {
    final usersBox = Hive.box('usersBox');
    final user = usersBox.get(widget.username) as Map?;

    if (user == null) return false;

    // Get default permissions for this level
    final defaults = UserPermissions.getDefaultPermissions(widget.level);
    
    // Check custom permissions, fall back to defaults if not set
    if (user['permissions'] != null) {
      final permissions = Map<String, bool>.from(user['permissions'] as Map);
      // If permission is explicitly set, use that value
      // Otherwise fall back to default for this level
      return permissions.containsKey(permission) 
          ? permissions[permission]! 
          : (defaults[permission] ?? false);
    }

    // No custom permissions, use defaults
    return defaults[permission] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOperator = widget.level == 1;
    // final bool isMaterial = widget.level == 2; // Reserved for future use
    final bool isSetter = widget.level == 3;
    final bool isManager = widget.level >= 4;
    final bool isAdmin = widget.level >= 4;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('User: ${widget.username}',
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (int index) {},
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CC9F0), Color(0xFF80ED99)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.factory, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'ProMould v7.2',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  'Smart Factory',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Operator Menu (Level 1) - Only Dashboard and QC
          if (isOperator) ...[
            if (_hasPermission(UserPermissions.dashboard))
              _drawerItem(
                  Icons.dashboard_outlined,
                  'Dashboard',
                  DashboardScreenV2(
                      username: widget.username, level: widget.level)),
            _drawerItem(Icons.report_problem_outlined, 'Report Issue',
                OperatorQCScreen(username: widget.username)),
          ],
          // Setter Menu (Level 3) - Limited access
          if (isSetter) ...[
            if (_hasPermission(UserPermissions.dashboard))
              _drawerItem(
                  Icons.dashboard_outlined,
                  'Dashboard',
                  DashboardScreenV2(
                      username: widget.username, level: widget.level)),
            _drawerItem(Icons.swap_horiz, 'Mould Changes',
                MouldChangeSchedulerScreen(level: widget.level)),
            if (_hasPermission(UserPermissions.mouldChangeChecklist))
              _drawerItem(Icons.checklist, 'Mould Change Checklist',
                  MouldChangeChecklistScreen(level: widget.level)),
            if (_hasPermission(UserPermissions.mouldChangeHistory))
              _drawerItem(Icons.history, 'Mould Change History',
                  const MouldChangeHistoryScreen()),
            _drawerItem(
                Icons.fact_check,
                'Machine Inspections',
                MachineInspectionChecklistScreen(
                    level: widget.level, username: widget.username)),
            _drawerItem(Icons.task_alt, 'My Tasks',
                MyTasksScreen(username: widget.username, level: widget.level)),
            _drawerItem(Icons.report_problem_outlined, 'Issues',
                IssuesScreenV2(username: widget.username, level: widget.level)),
          ],
          // Manager Menu (Level 4+)
          if (isManager) ...[
            if (_hasPermission(UserPermissions.dashboard))
              _drawerItem(
                  Icons.dashboard_outlined,
                  'Dashboard',
                  DashboardScreenV2(
                      username: widget.username, level: widget.level)),
            _drawerItem(Icons.calendar_month_outlined, 'Timeline',
                TimelineScreenV2(level: widget.level)),
            _drawerItem(
                Icons.edit_note_outlined,
                'Inputs',
                DailyInputScreen(
                    username: widget.username, level: widget.level)),
            _drawerItem(
                Icons.assignment_outlined,
                'Daily Production Sheet',
                DailyProductionSheetScreen(
                    username: widget.username, level: widget.level)),
            _drawerItem(Icons.report_problem_outlined, 'Issues',
                IssuesScreenV2(username: widget.username, level: widget.level)),
            _drawerItem(Icons.task_alt, 'My Tasks',
                MyTasksScreen(username: widget.username, level: widget.level)),
          ],
          if (isManager) const Divider(),
          if (isManager)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('MANAGEMENT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54)),
            ),
          if (isManager && _hasPermission(UserPermissions.machines))
            _drawerItem(Icons.precision_manufacturing_outlined, 'Machines',
                ManageMachinesScreen(level: widget.level)),
          if (isManager && _hasPermission(UserPermissions.jobs))
            _drawerItem(Icons.fact_check_outlined, 'Jobs',
                ManageJobsScreen(level: widget.level)),
          if (isManager && _hasPermission(UserPermissions.jobs))
            _drawerItem(Icons.reorder, 'Job Queue',
                JobQueueManagerScreen(level: widget.level)),
          if (isManager)
            _drawerItem(Icons.apps_outage_outlined, 'Moulds',
                ManageMouldsScreen(level: widget.level)),
          if (isManager)
            _drawerItem(Icons.swap_horiz, 'Mould Changes',
                MouldChangeSchedulerScreen(level: widget.level)),
          if (isManager && _hasPermission(UserPermissions.mouldChangeChecklist))
            _drawerItem(Icons.checklist, 'Mould Change Checklist',
                MouldChangeChecklistScreen(level: widget.level)),
          if (isManager && _hasPermission(UserPermissions.mouldChangeHistory))
            _drawerItem(Icons.history, 'Mould Change History',
                const MouldChangeHistoryScreen()),
          if (isManager)
            _drawerItem(Icons.apartment_outlined, 'Floors',
                ManageFloorsScreen(level: widget.level)),
          if (isAdmin && _hasPermission(UserPermissions.userManagement))
            _drawerItem(Icons.manage_accounts_outlined, 'Users',
                ManageUsersScreen(level: widget.level)),
          if (isManager)
            _drawerItem(Icons.schedule_outlined, 'Production Timeline',
                const ProductionTimelineScreen()),
          if (isManager)
            _drawerItem(Icons.timeline_outlined, 'Planning',
                PlanningScreen(level: widget.level)),
          if (isManager)
            _drawerItem(Icons.timer_outlined, 'Downtime',
                DowntimeScreen(level: widget.level)),
          if (isManager)
            _drawerItem(
                Icons.fact_check,
                'Machine Inspections',
                MachineInspectionChecklistScreen(
                    level: widget.level, username: widget.username)),
          if (isManager)
            _drawerItem(Icons.assessment, 'Inspection Tracking',
                const DailyInspectionTrackingScreen()),
          if (isManager)
            _drawerItem(Icons.archive_outlined, 'Finished Jobs',
                const FinishedJobsScreen()),
          if (isManager)
            _drawerItem(Icons.analytics_outlined, 'Job Analytics',
                const JobAnalyticsScreen()),
          if (isManager && _hasPermission(UserPermissions.reports))
            _drawerItem(Icons.insights_outlined, 'Reports / OEE',
                OEEScreen(level: widget.level)),
          if (isManager)
            _drawerItem(
                Icons.verified_outlined,
                'Quality Control',
                QualityControlScreen(
                    level: widget.level, username: widget.username)),
          if (isAdmin) const Divider(),
          if (isAdmin && _hasPermission(UserPermissions.userPermissions))
            _drawerItem(Icons.admin_panel_settings_outlined,
                'User Permissions', const UserPermissionsScreen()),
          if (isAdmin && _hasPermission(UserPermissions.settings))
            _drawerItem(Icons.settings_outlined, 'Settings',
                SettingsScreen(level: widget.level)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app_outlined,
                color: Color(0xFFFF6B6B)),
            title: const Text('Logout',
                style: TextStyle(color: Color(0xFFFF6B6B))),
            onTap: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Close drawer
                        // Navigate back to login and remove all routes
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B)),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _activeScreen,
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget screen) {
    final bool selected = _title == title;
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFF4CC9F0) : null),
      title: Text(title,
          style: TextStyle(
              color: selected ? const Color(0xFF4CC9F0) : null,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      onTap: () => _navigate(title, screen),
    );
  }
}
