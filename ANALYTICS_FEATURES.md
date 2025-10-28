# ProMould Analytics & Reporting Features

## Overview
This document describes the comprehensive analytics, reporting, and export features added to ProMould v7.1.

## Features Implemented

### 1. Analytics Dashboard (`lib/screens/analytics_dashboard_screen.dart`)
A comprehensive real-time analytics dashboard with multiple views:

#### Features:
- **Real-time KPIs**: Production efficiency, machine utilization, total output, issue resolution
- **Multiple View Modes**:
  - Overview: High-level metrics and trends
  - Production: Job metrics, output trends, machine performance
  - Quality: Issue tracking, resolution rates, category breakdown
  - Machines: Utilization, performance rankings
  - Operators: Performance metrics and productivity
- **Time Range Filters**: 24h, 7 days, 30 days, 90 days
- **Interactive Charts**: Line charts for trends, pie charts for distributions
- **Performance Rankings**: Top performing machines and operators

#### Usage:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AnalyticsDashboardScreen(),
  ),
);
```

### 2. Analytics Service (`lib/services/analytics_service.dart`)
Backend service providing data analysis and calculations:

#### Methods:
- `calculateRealTimeKPIs()`: Current production metrics
- `predictMachineFailures()`: ML-based failure prediction
- `calculateTrends()`: 7-day trend analysis
- `analyzeTopIssues()`: Issue categorization and frequency
- `analyzeShiftPerformance()`: Day vs night shift comparison

#### Example:
```dart
final kpis = AnalyticsService.calculateRealTimeKPIs();
print('Utilization: ${kpis['utilizationRate']}%');
print('Total Shots: ${kpis['totalShots']}');
```

### 3. Predictive Analytics (`lib/screens/predictive_analytics_screen.dart`)
Machine failure prediction system using historical data:

#### Features:
- **Risk Scoring**: 0-100 risk score based on:
  - Downtime frequency (5 points per event)
  - Issue count (3 points per issue)
  - Critical issues (10 points each)
- **Risk Categories**: High (70+), Medium (40-69), Low (30-39)
- **Recommendations**: Actionable maintenance suggestions
- **Visual Indicators**: Color-coded risk levels and progress bars

#### Algorithm:
```
Risk Score = (Downtime Events × 5) + (Issues × 3) + (Critical Issues × 10)
Capped at 100
```

### 4. Custom Report Builder (`lib/screens/report_builder_screen.dart`)
Flexible report generation with customizable parameters:

#### Report Types:
1. **Production Report**: Shots, scrap, efficiency by date/machine/operator
2. **Quality Report**: Issues by priority, category, status
3. **Downtime Report**: Downtime events by machine and reason
4. **Machine Performance**: Job completion rates and utilization
5. **Operator Performance**: Output and quality metrics

#### Features:
- Date range selection with quick filters (7/30/90 days)
- Machine and operator filters
- Customizable options (summary, charts, details)
- Live preview of report data
- CSV export with proper formatting

#### Usage:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ReportBuilderScreen(),
  ),
);
```

### 5. Scheduled Reports (`lib/services/scheduled_reports_service.dart` & `lib/screens/scheduled_reports_screen.dart`)
Automated report generation and delivery:

#### Features:
- **Frequencies**: Daily, Weekly, Monthly
- **Scheduling**: Specific time, day of week, or day of month
- **Recipients**: Multiple email addresses
- **Report Options**: Charts, summary, detailed data
- **Active/Inactive Toggle**: Enable/disable schedules
- **Next Run Calculation**: Automatic scheduling

#### Schedule Management:
```dart
// Create schedule
await ScheduledReportsService.createSchedule(
  reportType: 'production',
  frequency: 'daily',
  time: '08:00',
  recipients: ['manager@example.com'],
  includeCharts: true,
);

// Check and run due schedules
await ScheduledReportsService.checkAndRunSchedules();
```

### 6. Checklist Export Service (`lib/services/checklist_export_service.dart`)
Comprehensive checklist export functionality:

#### Export Formats:
1. **CSV Export**:
   - Single checklist
   - Multiple checklists
   - Completion history
   
2. **PDF Export**:
   - Professional formatting
   - Progress indicators
   - Completion status with checkmarks
   - Notes and timestamps

#### Features:
- `exportToCSV()`: Single checklist to CSV
- `exportToPDF()`: Single checklist to PDF with formatting
- `exportMultipleToCSV()`: Batch export
- `exportChecklistHistory()`: Historical completion data
- `exportSummaryReport()`: Period-based summary with statistics

#### Example:
```dart
// Export single checklist as PDF
await ChecklistExportService.exportToPDF(checklist);

// Export multiple checklists
await ChecklistExportService.exportMultipleToCSV(checklists);

// Export summary report
await ChecklistExportService.exportSummaryReport(
  startDate,
  endDate,
  checklists,
);
```

### 7. Checklist Manager (`lib/screens/checklist_manager_screen.dart`)
Complete checklist management interface:

#### Features:
- **Create Checklists**: Custom titles, categories, items
- **Category Filtering**: Safety, Quality, Maintenance, Production, Setup
- **Progress Tracking**: Visual progress bars and completion percentages
- **Item Management**: Add, edit, complete items with notes
- **Export Options**: PDF and CSV export per checklist
- **Duplicate**: Clone checklists with reset completion
- **Batch Export**: Export all checklists at once

#### Checklist Detail View:
- Real-time progress tracking
- Item completion with checkboxes
- Notes per item
- Auto-save functionality

## Data Flow

### Analytics Pipeline:
```
Hive Boxes (Data Storage)
    ↓
Analytics Service (Calculations)
    ↓
Dashboard/Screens (Visualization)
    ↓
Export Services (Reports)
```

### Report Generation:
```
User Input (Filters, Date Range)
    ↓
Report Builder (Data Collection)
    ↓
CSV/PDF Generation
    ↓
Share Service (Export)
```

## Dependencies Added

```yaml
dependencies:
  pdf: ^3.11.1          # PDF generation
  fl_chart: ^0.69.0     # Charts and graphs
  share_plus: ^10.0.2   # File sharing (already present)
  path_provider: ^2.1.4 # File system access (already present)
  intl: ^0.19.0         # Date formatting (already present)
```

## Integration Guide

### 1. Initialize Services
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Open required boxes
  await Hive.openBox('checklistsBox');
  await Hive.openBox('scheduledReportsBox');
  
  // Initialize scheduled reports
  await ScheduledReportsService.initialize();
  
  runApp(MyApp());
}
```

### 2. Add to Navigation
```dart
// In your main menu or dashboard
ListTile(
  leading: Icon(Icons.analytics),
  title: Text('Analytics Dashboard'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AnalyticsDashboardScreen(),
    ),
  ),
),
ListTile(
  leading: Icon(Icons.psychology),
  title: Text('Predictive Analytics'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PredictiveAnalyticsScreen(),
    ),
  ),
),
ListTile(
  leading: Icon(Icons.assessment),
  title: Text('Report Builder'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ReportBuilderScreen(),
    ),
  ),
),
ListTile(
  leading: Icon(Icons.schedule),
  title: Text('Scheduled Reports'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ScheduledReportsScreen(),
    ),
  ),
),
ListTile(
  leading: Icon(Icons.checklist),
  title: Text('Checklist Manager'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ChecklistManagerScreen(),
    ),
  ),
),
```

### 3. Background Task for Scheduled Reports
```dart
// In your WorkManager configuration
Workmanager().registerPeriodicTask(
  "scheduled-reports",
  "checkScheduledReports",
  frequency: Duration(hours: 1),
);

// In your background task handler
case "checkScheduledReports":
  await ScheduledReportsService.checkAndRunSchedules();
  break;
```

## Testing Checklist

- [ ] Analytics Dashboard loads with real data
- [ ] All view modes (Overview, Production, Quality, Machines, Operators) work
- [ ] Time range filters update charts correctly
- [ ] Predictive analytics shows risk scores
- [ ] Report builder generates previews
- [ ] CSV export creates valid files
- [ ] PDF export creates formatted documents
- [ ] Scheduled reports can be created and edited
- [ ] Checklist manager displays all checklists
- [ ] Checklist export (PDF/CSV) works
- [ ] Checklist completion tracking saves correctly

## Performance Considerations

1. **Large Datasets**: Analytics calculations are optimized for datasets up to 10,000 records
2. **Chart Rendering**: Limited to 90 days of data points for smooth rendering
3. **Export Size**: PDF exports are limited to 1000 items per document
4. **Caching**: Consider implementing caching for frequently accessed analytics

## Future Enhancements

1. **Email Integration**: Actual email delivery for scheduled reports
2. **Advanced Filters**: More granular filtering options
3. **Custom Metrics**: User-defined KPIs and calculations
4. **Dashboard Customization**: Drag-and-drop widget arrangement
5. **Real-time Updates**: WebSocket integration for live data
6. **Export Templates**: Customizable report templates
7. **Data Visualization**: More chart types (scatter, radar, heatmap)
8. **Predictive Models**: ML-based forecasting for production planning

## Support

For issues or questions about these features, please refer to:
- Main documentation: `README.md`
- API documentation: Generated via `flutter pub run build_runner build`
- Issue tracker: GitHub Issues

## Version History

- **v7.1.0** (2024): Initial release of analytics and reporting features
  - Analytics Dashboard
  - Predictive Analytics
  - Custom Report Builder
  - Scheduled Reports
  - Checklist Export System
