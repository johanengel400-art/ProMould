# Navigation Integration Guide

## Adding New Screens to App Menu

This guide shows how to integrate the new Finished Jobs and Job Analytics screens into the ProMould navigation menu.

---

## Option 1: Add to Main Drawer Menu

If your app uses a drawer menu, add these entries:

```dart
// In your drawer widget (typically in main screen or app scaffold)

ListTile(
  leading: Icon(Icons.archive, color: Color(0xFF4CC9F0)),
  title: Text('Finished Jobs'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinishedJobsScreen(),
      ),
    );
  },
),

ListTile(
  leading: Icon(Icons.analytics, color: Color(0xFFFFD166)),
  title: Text('Job Analytics'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobAnalyticsScreen(),
      ),
    );
  },
),
```

**Don't forget to import:**
```dart
import 'screens/finished_jobs_screen.dart';
import 'screens/job_analytics_screen.dart';
```

---

## Option 2: Add to Bottom Navigation Bar

If using bottom navigation:

```dart
// Add to your bottom navigation items
BottomNavigationBarItem(
  icon: Icon(Icons.archive),
  label: 'Finished',
),

BottomNavigationBarItem(
  icon: Icon(Icons.analytics),
  label: 'Analytics',
),

// Add corresponding screens to your page list
final List<Widget> _pages = [
  // ... existing pages
  FinishedJobsScreen(),
  JobAnalyticsScreen(),
];
```

---

## Option 3: Add to Dashboard Quick Actions

Add quick action cards on the dashboard:

```dart
// In dashboard_screen_v2.dart or similar

Row(
  children: [
    Expanded(
      child: _buildQuickActionCard(
        'Finished Jobs',
        Icons.archive,
        Color(0xFF4CC9F0),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinishedJobsScreen(),
          ),
        ),
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: _buildQuickActionCard(
        'Analytics',
        Icons.analytics,
        Color(0xFFFFD166),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobAnalyticsScreen(),
          ),
        ),
      ),
    ),
  ],
)

Widget _buildQuickActionCard(
  String title,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            Color(0xFF1A1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## Option 4: Add to Reports/Analytics Section

If you have a reports section:

```dart
// In reports or analytics menu

Card(
  child: ListTile(
    leading: Icon(Icons.archive, color: Color(0xFF4CC9F0)),
    title: Text('Finished Jobs Archive'),
    subtitle: Text('View completed jobs by date'),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FinishedJobsScreen()),
    ),
  ),
),

Card(
  child: ListTile(
    leading: Icon(Icons.analytics, color: Color(0xFFFFD166)),
    title: Text('Job Analytics'),
    subtitle: Text('Overrun metrics and trends'),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobAnalyticsScreen()),
    ),
  ),
),
```

---

## Recommended Placement by User Level

### Level 1 (Operators)
- **Dashboard:** Quick action to view finished jobs
- **Limited Access:** May not need analytics

### Level 2 (Supervisors)
- **Main Menu:** Both finished jobs and analytics
- **Dashboard:** Quick actions for both

### Level 3+ (Managers/Admins)
- **Main Menu:** Prominent placement
- **Dashboard:** Featured quick actions
- **Reports Section:** Detailed access

---

## Access Control Example

If you want to restrict access by user level:

```dart
// Only show analytics to level 2+
if (userLevel >= 2) {
  ListTile(
    leading: Icon(Icons.analytics, color: Color(0xFFFFD166)),
    title: Text('Job Analytics'),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => JobAnalyticsScreen()),
      );
    },
  ),
}

// Show finished jobs to all users
ListTile(
  leading: Icon(Icons.archive, color: Color(0xFF4CC9F0)),
  title: Text('Finished Jobs'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FinishedJobsScreen()),
    ),
  ),
),
```

---

## Deep Linking (Optional)

For direct navigation from notifications or external links:

```dart
// In your route handler
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/finished-jobs':
      return MaterialPageRoute(builder: (_) => FinishedJobsScreen());
    case '/analytics':
      return MaterialPageRoute(builder: (_) => JobAnalyticsScreen());
    // ... other routes
    default:
      return MaterialPageRoute(builder: (_) => DashboardScreen());
  }
}

// Navigate using named routes
Navigator.pushNamed(context, '/finished-jobs');
Navigator.pushNamed(context, '/analytics');
```

---

## Navigation with Parameters

To open finished jobs for a specific date:

```dart
// Navigate to finished jobs with specific date
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FinishedJobsScreen(
      initialDate: DateTime(2024, 11, 10),
    ),
  ),
);
```

**Update FinishedJobsScreen constructor:**
```dart
class FinishedJobsScreen extends StatefulWidget {
  final DateTime? initialDate;
  
  const FinishedJobsScreen({super.key, this.initialDate});

  @override
  State<FinishedJobsScreen> createState() => _FinishedJobsScreenState();
}

class _FinishedJobsScreenState extends State<FinishedJobsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadJobs();
  }
  // ... rest of implementation
}
```

---

## Contextual Navigation

Navigate from dashboard overrun alert:

```dart
// In dashboard alerts panel
GestureDetector(
  onTap: () {
    // Navigate to analytics filtered for overruns
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobAnalyticsScreen(
          showOverrunsOnly: true,
        ),
      ),
    );
  },
  child: Container(
    // ... alert UI
    child: Text('$overrunningJobs jobs overrunning - Tap to view'),
  ),
)
```

---

## Breadcrumb Navigation

For better UX, add breadcrumbs:

```dart
// In finished jobs or analytics screen
AppBar(
  title: Row(
    children: [
      Text('Reports'),
      Icon(Icons.chevron_right, size: 16),
      Text('Finished Jobs'),
    ],
  ),
)
```

---

## Tab Navigation

If using tabs in a reports section:

```dart
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      title: Text('Reports'),
      bottom: TabBar(
        tabs: [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.archive), text: 'Finished Jobs'),
          Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        ReportsOverviewScreen(),
        FinishedJobsScreen(),
        JobAnalyticsScreen(),
      ],
    ),
  ),
)
```

---

## Search Integration

Add to app-wide search:

```dart
// In search results
if (query.toLowerCase().contains('finished') || 
    query.toLowerCase().contains('archive')) {
  results.add(
    SearchResult(
      title: 'Finished Jobs',
      subtitle: 'View completed jobs archive',
      icon: Icons.archive,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FinishedJobsScreen()),
      ),
    ),
  );
}

if (query.toLowerCase().contains('analytics') || 
    query.toLowerCase().contains('overrun')) {
  results.add(
    SearchResult(
      title: 'Job Analytics',
      subtitle: 'Overrun metrics and trends',
      icon: Icons.analytics,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => JobAnalyticsScreen()),
      ),
    ),
  );
}
```

---

## Recommended Implementation

For ProMould, we recommend:

1. **Main Drawer Menu:**
   - Add under "Reports" or "Jobs" section
   - Icons: Archive (finished jobs), Analytics (analytics)
   - Available to all authenticated users

2. **Dashboard Quick Actions:**
   - Add cards for quick access
   - Show overrun count on analytics card
   - Prominent placement for supervisors+

3. **Contextual Links:**
   - From overrun alerts → Analytics
   - From manage jobs → Finished jobs
   - From machine detail → Analytics for that machine

---

## Example Complete Integration

```dart
// In your main drawer or menu screen

// Jobs Section
ExpansionTile(
  leading: Icon(Icons.work_outline),
  title: Text('Jobs'),
  children: [
    ListTile(
      leading: Icon(Icons.list),
      title: Text('Manage Jobs'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ManageJobsScreen()),
      ),
    ),
    ListTile(
      leading: Icon(Icons.archive, color: Color(0xFF4CC9F0)),
      title: Text('Finished Jobs'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FinishedJobsScreen()),
      ),
    ),
  ],
),

// Reports Section
ExpansionTile(
  leading: Icon(Icons.assessment),
  title: Text('Reports'),
  children: [
    ListTile(
      leading: Icon(Icons.analytics, color: Color(0xFFFFD166)),
      title: Text('Job Analytics'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => JobAnalyticsScreen()),
      ),
    ),
    // ... other reports
  ],
),
```

---

## Testing Navigation

After integration, test:
- [ ] Can navigate to Finished Jobs from menu
- [ ] Can navigate to Job Analytics from menu
- [ ] Back button works correctly
- [ ] Deep links work (if implemented)
- [ ] Access control works (if implemented)
- [ ] Contextual navigation works
- [ ] No navigation loops or dead ends

---

**Next Steps:**
1. Choose navigation pattern(s) for your app
2. Add imports to relevant files
3. Implement navigation code
4. Test thoroughly
5. Update user documentation

---

**Last Updated:** November 10, 2024
