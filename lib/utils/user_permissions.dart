/// User permissions system for controlling page visibility
class UserPermissions {
  // Available pages/features
  static const String dashboard = 'dashboard';
  static const String machines = 'machines';
  static const String jobs = 'jobs';
  static const String moulds = 'moulds';
  static const String mouldChanges = 'mould_changes';
  static const String mouldChangeChecklist = 'mould_change_checklist';
  static const String mouldChangeHistory = 'mould_change_history';
  static const String machineInspections = 'machine_inspections';
  static const String dailyInspections = 'daily_inspections';
  static const String myTasks = 'my_tasks';
  static const String issues = 'issues';
  static const String qualityControl = 'quality_control';
  static const String qualityHolds = 'quality_holds';
  static const String jobcardCapture = 'jobcard_capture';
  static const String dailyInput = 'daily_input';
  static const String floors = 'floors';
  static const String jobQueue = 'job_queue';
  static const String analytics = 'analytics';
  static const String scrapAnalysis = 'scrap_analysis';
  static const String checklistManager = 'checklist_manager';
  static const String manageUsers = 'manage_users';
  static const String settings = 'settings';

  // Default permissions by level
  static Map<String, bool> getDefaultPermissions(int level) {
    switch (level) {
      case 1: // Operator
        return {
          dashboard: true,
          myTasks: true,
          issues: true,
          dailyInput: true,
          machineInspections: true,
          mouldChangeChecklist: true,
          settings: false,
          manageUsers: false,
          machines: false,
          jobs: false,
          moulds: false,
          mouldChanges: false,
          mouldChangeHistory: true,
          dailyInspections: false,
          qualityControl: false,
          qualityHolds: false,
          jobcardCapture: false,
          floors: false,
          jobQueue: false,
          analytics: false,
          scrapAnalysis: false,
          checklistManager: false,
        };
      case 2: // Supervisor
        return {
          dashboard: true,
          myTasks: true,
          issues: true,
          dailyInput: true,
          machineInspections: true,
          mouldChangeChecklist: true,
          mouldChangeHistory: true,
          jobcardCapture: true,
          qualityControl: true,
          settings: false,
          manageUsers: false,
          machines: false,
          jobs: false,
          moulds: false,
          mouldChanges: true,
          dailyInspections: true,
          qualityHolds: true,
          floors: false,
          jobQueue: false,
          analytics: false,
          scrapAnalysis: false,
          checklistManager: false,
        };
      case 3: // Manager
        return {
          dashboard: true,
          machines: true,
          jobs: true,
          moulds: true,
          mouldChanges: true,
          mouldChangeChecklist: true,
          mouldChangeHistory: true,
          machineInspections: true,
          dailyInspections: true,
          myTasks: true,
          issues: true,
          qualityControl: true,
          qualityHolds: true,
          jobcardCapture: true,
          dailyInput: true,
          floors: true,
          jobQueue: true,
          analytics: true,
          scrapAnalysis: true,
          checklistManager: true,
          manageUsers: false,
          settings: false,
        };
      case 4: // Admin
        return {
          dashboard: true,
          machines: true,
          jobs: true,
          moulds: true,
          mouldChanges: true,
          mouldChangeChecklist: true,
          mouldChangeHistory: true,
          machineInspections: true,
          dailyInspections: true,
          myTasks: true,
          issues: true,
          qualityControl: true,
          qualityHolds: true,
          jobcardCapture: true,
          dailyInput: true,
          floors: true,
          jobQueue: true,
          analytics: true,
          scrapAnalysis: true,
          checklistManager: true,
          manageUsers: true,
          settings: true,
        };
      default:
        return {};
    }
  }

  // Get page display name
  static String getPageName(String permission) {
    switch (permission) {
      case dashboard:
        return 'Dashboard';
      case machines:
        return 'Machines';
      case jobs:
        return 'Jobs';
      case moulds:
        return 'Moulds';
      case mouldChanges:
        return 'Mould Changes';
      case mouldChangeChecklist:
        return 'Mould Change Checklist';
      case mouldChangeHistory:
        return 'Mould Change History';
      case machineInspections:
        return 'Machine Inspections';
      case dailyInspections:
        return 'Daily Inspections';
      case myTasks:
        return 'My Tasks';
      case issues:
        return 'Issues';
      case qualityControl:
        return 'Quality Control';
      case qualityHolds:
        return 'Quality Holds';
      case jobcardCapture:
        return 'Jobcard Capture';
      case dailyInput:
        return 'Daily Input';
      case floors:
        return 'Floors';
      case jobQueue:
        return 'Job Queue';
      case analytics:
        return 'Analytics';
      case scrapAnalysis:
        return 'Scrap Analysis';
      case checklistManager:
        return 'Checklist Manager';
      case manageUsers:
        return 'Manage Users';
      case settings:
        return 'Settings';
      default:
        return permission;
    }
  }

  // Get all available permissions
  static List<String> getAllPermissions() {
    return [
      dashboard,
      machines,
      jobs,
      moulds,
      mouldChanges,
      mouldChangeChecklist,
      mouldChangeHistory,
      machineInspections,
      dailyInspections,
      myTasks,
      issues,
      qualityControl,
      qualityHolds,
      jobcardCapture,
      dailyInput,
      floors,
      jobQueue,
      analytics,
      scrapAnalysis,
      checklistManager,
      manageUsers,
      settings,
    ];
  }
}
