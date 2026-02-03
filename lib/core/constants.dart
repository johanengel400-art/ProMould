/// ProMould Core Constants
/// Single source of truth for all system-wide constants

library promould_constants;

/// User roles in the system - ordered by permission level
enum UserRole {
  operator(1, 'Operator'),
  materialHandler(2, 'Material Handler'),
  qc(2, 'Quality Control'),
  setter(3, 'Setter'),
  productionManager(4, 'Production Manager');

  final int level;
  final String displayName;
  const UserRole(this.level, this.displayName);

  bool canAccess(int requiredLevel) => level >= requiredLevel;
  bool canManage(UserRole other) => level > other.level;
}

/// Machine operational states
enum MachineStatus {
  running('Running', 'Machine is producing parts'),
  idle('Idle', 'Machine is available but not running'),
  down('Down', 'Machine is broken down'),
  setup('Setup', 'Machine is being set up for a job'),
  maintenance('Maintenance', 'Machine is under maintenance');

  final String displayName;
  final String description;
  const MachineStatus(this.displayName, this.description);

  bool get isProductive => this == running;
  bool get isAvailable => this == idle;
  bool get requiresAttention => this == down || this == maintenance;
}

/// Mould lifecycle states
enum MouldStatus {
  active('Active', 'Mould is available for production'),
  inUse('In Use', 'Mould is currently mounted on a machine'),
  maintenance('Maintenance', 'Mould is under maintenance'),
  repair('Repair', 'Mould is being repaired'),
  retired('Retired', 'Mould is no longer in service'),
  scrapped('Scrapped', 'Mould has been scrapped');

  final String displayName;
  final String description;
  const MouldStatus(this.displayName, this.description);

  bool get isUsable => this == active || this == inUse;
}

/// Job lifecycle states
enum JobStatus {
  pending('Pending', 'Job is created but not scheduled'),
  queued('Queued', 'Job is in the queue waiting to run'),
  running('Running', 'Job is currently in production'),
  paused('Paused', 'Job is temporarily paused'),
  complete('Complete', 'Job has finished production'),
  onHold('On Hold', 'Job is on hold due to quality or other issues'),
  cancelled('Cancelled', 'Job has been cancelled');

  final String displayName;
  final String description;
  const JobStatus(this.displayName, this.description);

  bool get isActive => this == running || this == paused;
  bool get canStart => this == pending || this == queued;
  bool get isFinal => this == complete || this == cancelled;
}

/// Task states
enum TaskStatus {
  pending('Pending', 'Task is created but not started'),
  assigned('Assigned', 'Task is assigned to a user'),
  inProgress('In Progress', 'Task is being worked on'),
  complete('Complete', 'Task is finished'),
  blocked('Blocked', 'Task cannot proceed'),
  cancelled('Cancelled', 'Task has been cancelled');

  final String displayName;
  final String description;
  const TaskStatus(this.displayName, this.description);

  bool get isOpen => this == pending || this == assigned || this == inProgress || this == blocked;
}

/// Task priority levels
enum TaskPriority {
  critical(1, 'Critical', Duration(minutes: 15)),
  high(2, 'High', Duration(minutes: 30)),
  medium(3, 'Medium', Duration(hours: 2)),
  low(4, 'Low', Duration(hours: 8));

  final int level;
  final String displayName;
  final Duration escalationThreshold;
  const TaskPriority(this.level, this.displayName, this.escalationThreshold);
}

/// Alert severity levels
enum AlertSeverity {
  critical(1, 'Critical'),
  high(2, 'High'),
  medium(3, 'Medium'),
  low(4, 'Low');

  final int level;
  final String displayName;
  const AlertSeverity(this.level, this.displayName);
}

/// Alert types
enum AlertType {
  machineDown('Machine Down'),
  jobCompletion('Job Completion'),
  jobOverrun('Job Overrun'),
  highScrap('High Scrap Rate'),
  cycleDeviation('Cycle Time Deviation'),
  materialShortage('Material Shortage'),
  qualityHold('Quality Hold'),
  maintenanceDue('Maintenance Due'),
  mouldChangeDue('Mould Change Due'),
  checklistOverdue('Checklist Overdue'),
  taskOverdue('Task Overdue'),
  counterReconciliation('Counter Reconciliation'),
  shiftHandover('Shift Handover'),
  certificationExpiry('Certification Expiry'),
  stockLow('Stock Low');

  final String displayName;
  const AlertType(this.displayName);
}

/// Downtime categories
enum DowntimeCategory {
  planned('Planned'),
  unplanned('Unplanned');

  final String displayName;
  const DowntimeCategory(this.displayName);
}

/// Quality inspection types
enum InspectionType {
  firstArticle('First Article'),
  inProcess('In-Process'),
  finalInspection('Final'),
  random('Random');

  final String displayName;
  const InspectionType(this.displayName);
}

/// Quality hold severity
enum HoldSeverity {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String displayName;
  const HoldSeverity(this.displayName);
}

/// Audit action types
enum AuditAction {
  create('Create'),
  update('Update'),
  delete('Delete'),
  override('Override'),
  login('Login'),
  logout('Logout'),
  statusChange('Status Change'),
  assignment('Assignment'),
  reconciliation('Reconciliation'),
  approval('Approval'),
  rejection('Rejection'),
  escalation('Escalation');

  final String displayName;
  const AuditAction(this.displayName);
}

/// System thresholds and limits
class SystemThresholds {
  // Scrap rate thresholds (percentage)
  static const double scrapExcellent = 2.0;
  static const double scrapAcceptable = 5.0;
  static const double scrapConcerning = 10.0;

  // OEE thresholds (percentage)
  static const double oeeWorldClass = 85.0;
  static const double oeeGood = 60.0;
  static const double oeeFair = 40.0;

  // Health score thresholds
  static const int healthExcellent = 90;
  static const int healthGood = 70;
  static const int healthFair = 50;

  // Counter reconciliation variance threshold (percentage)
  static const double counterVarianceThreshold = 5.0;

  // Escalation levels
  static const int maxEscalationLevel = 3;

  // Session timeout (minutes)
  static const int sessionTimeoutMinutes = 480; // 8 hours

  // Failed login attempts before lockout
  static const int maxFailedLoginAttempts = 5;

  // Lockout duration (minutes)
  static const int lockoutDurationMinutes = 30;

  // Job completion warning (minutes before ETA)
  static const int jobCompletionWarningMinutes = 30;

  // Maintenance due warning (percentage of interval)
  static const double maintenanceDueWarningPercent = 90.0;

  // Cycle time deviation threshold (percentage)
  static const double cycleTimeDeviationThreshold = 10.0;

  // Live counter refresh interval (seconds)
  static const int liveCounterRefreshSeconds = 5;

  // UI refresh interval (seconds)
  static const int uiRefreshSeconds = 3;

  // Notification check interval (seconds)
  static const int notificationCheckSeconds = 30;
}

/// Hive box names - single source of truth
class HiveBoxes {
  static const String users = 'usersBox';
  static const String floors = 'floorsBox';
  static const String machines = 'machinesBox';
  static const String moulds = 'mouldsBox';
  static const String jobs = 'jobsBox';
  static const String materials = 'materialsBox';
  static const String tools = 'toolsBox';
  static const String issues = 'issuesBox';
  static const String inputs = 'inputsBox';
  static const String queue = 'queueBox';
  static const String downtime = 'downtimeBox';
  static const String scrap = 'scrapBox';
  static const String checklists = 'checklistsBox';
  static const String mouldChanges = 'mouldChangesBox';
  static const String qualityInspections = 'qualityInspectionsBox';
  static const String qualityHolds = 'qualityHoldsBox';
  static const String machineInspections = 'machineInspectionsBox';
  static const String dailyInspections = 'dailyInspectionsBox';
  static const String dailyProduction = 'dailyProductionBox';
  static const String tasks = 'tasksBox';
  static const String alerts = 'alertsBox';
  static const String shifts = 'shiftsBox';
  static const String handovers = 'handoversBox';
  static const String auditLogs = 'auditLogsBox';
  static const String productionLogs = 'productionLogsBox';
  static const String reconciliations = 'reconciliationsBox';
  static const String stockMovements = 'stockMovementsBox';
  static const String assignments = 'assignmentsBox';
  static const String compatibility = 'compatibilityBox';
  static const String reasonCodes = 'reasonCodesBox';
  static const String customers = 'customersBox';
  static const String suppliers = 'suppliersBox';
  static const String notifications = 'notificationsBox';
  static const String settings = 'settingsBox';

  static List<String> get all => [
        users,
        floors,
        machines,
        moulds,
        jobs,
        materials,
        tools,
        issues,
        inputs,
        queue,
        downtime,
        scrap,
        checklists,
        mouldChanges,
        qualityInspections,
        qualityHolds,
        machineInspections,
        dailyInspections,
        dailyProduction,
        tasks,
        alerts,
        shifts,
        handovers,
        auditLogs,
        productionLogs,
        reconciliations,
        stockMovements,
        assignments,
        compatibility,
        reasonCodes,
        customers,
        suppliers,
        notifications,
        settings,
      ];
}

/// Firebase collection names
class FirebaseCollections {
  static const String users = 'users';
  static const String floors = 'floors';
  static const String machines = 'machines';
  static const String moulds = 'moulds';
  static const String jobs = 'jobs';
  static const String materials = 'materials';
  static const String tools = 'tools';
  static const String issues = 'issues';
  static const String inputs = 'inputs';
  static const String queue = 'queue';
  static const String downtime = 'downtime';
  static const String scrap = 'scrap';
  static const String checklists = 'checklists';
  static const String mouldChanges = 'mouldChanges';
  static const String qualityInspections = 'qualityInspections';
  static const String qualityHolds = 'qualityHolds';
  static const String machineInspections = 'machineInspections';
  static const String dailyInspections = 'dailyInspections';
  static const String dailyProduction = 'dailyProduction';
  static const String tasks = 'tasks';
  static const String alerts = 'alerts';
  static const String shifts = 'shifts';
  static const String handovers = 'handovers';
  static const String auditLogs = 'auditLogs';
  static const String productionLogs = 'productionLogs';
  static const String reconciliations = 'reconciliations';
  static const String stockMovements = 'stockMovements';
  static const String assignments = 'assignments';
  static const String compatibility = 'compatibility';
  static const String reasonCodes = 'reasonCodes';
  static const String customers = 'customers';
  static const String suppliers = 'suppliers';
  static const String finishedJobs = 'finishedJobs';
  static const String resolvedIssues = 'resolvedIssues';
}
