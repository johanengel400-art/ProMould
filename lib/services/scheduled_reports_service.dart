import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'log_service.dart';

class ScheduledReportsService {
  static const _uuid = Uuid();

  static Future<void> initialize() async {
    await Hive.openBox('scheduledReportsBox');
  }

  static Future<String> createSchedule({
    required String reportType,
    required String frequency, // daily, weekly, monthly
    required String time, // HH:mm format
    String? dayOfWeek, // For weekly reports (Monday, Tuesday, etc.)
    int? dayOfMonth, // For monthly reports (1-31)
    String? machineId,
    String? operatorId,
    required List<String> recipients,
    bool includeCharts = true,
    bool includeSummary = true,
    bool includeDetails = true,
  }) async {
    final box = Hive.box('scheduledReportsBox');
    final id = _uuid.v4();

    final schedule = {
      'id': id,
      'reportType': reportType,
      'frequency': frequency,
      'time': time,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'machineId': machineId,
      'operatorId': operatorId,
      'recipients': recipients,
      'includeCharts': includeCharts,
      'includeSummary': includeSummary,
      'includeDetails': includeDetails,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'lastRun': null,
      'nextRun': _calculateNextRun(frequency, time, dayOfWeek, dayOfMonth),
    };

    await box.put(id, schedule);
    return id;
  }

  static Future<void> updateSchedule(
      String id, Map<String, dynamic> updates) async {
    final box = Hive.box('scheduledReportsBox');
    final schedule = box.get(id) as Map?;
    if (schedule == null) return;

    final updated = Map<String, dynamic>.from(schedule)..addAll(updates);

    // Recalculate next run if timing changed
    if (updates.containsKey('frequency') ||
        updates.containsKey('time') ||
        updates.containsKey('dayOfWeek') ||
        updates.containsKey('dayOfMonth')) {
      updated['nextRun'] = _calculateNextRun(
        updated['frequency'],
        updated['time'],
        updated['dayOfWeek'],
        updated['dayOfMonth'],
      );
    }

    await box.put(id, updated);
  }

  static Future<void> deleteSchedule(String id) async {
    final box = Hive.box('scheduledReportsBox');
    await box.delete(id);
  }

  static Future<void> toggleSchedule(String id, bool isActive) async {
    await updateSchedule(id, {'isActive': isActive});
  }

  static List<Map<String, dynamic>> getAllSchedules() {
    final box = Hive.box('scheduledReportsBox');
    return box.values
        .cast<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  static List<Map<String, dynamic>> getActiveSchedules() {
    return getAllSchedules().where((s) => s['isActive'] == true).toList();
  }

  static Map<String, dynamic>? getSchedule(String id) {
    final box = Hive.box('scheduledReportsBox');
    final schedule = box.get(id) as Map?;
    return schedule != null ? Map<String, dynamic>.from(schedule) : null;
  }

  static String _calculateNextRun(
    String frequency,
    String time,
    String? dayOfWeek,
    int? dayOfMonth,
  ) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    DateTime nextRun;

    switch (frequency) {
      case 'daily':
        nextRun = DateTime(now.year, now.month, now.day, hour, minute);
        if (nextRun.isBefore(now)) {
          nextRun = nextRun.add(const Duration(days: 1));
        }
        break;

      case 'weekly':
        final targetDay = _dayOfWeekToInt(dayOfWeek ?? 'Monday');
        nextRun = DateTime(now.year, now.month, now.day, hour, minute);

        while (nextRun.weekday != targetDay || nextRun.isBefore(now)) {
          nextRun = nextRun.add(const Duration(days: 1));
        }
        break;

      case 'monthly':
        final targetDay = dayOfMonth ?? 1;
        nextRun = DateTime(now.year, now.month, targetDay, hour, minute);

        if (nextRun.isBefore(now)) {
          // Move to next month
          if (now.month == 12) {
            nextRun = DateTime(now.year + 1, 1, targetDay, hour, minute);
          } else {
            nextRun =
                DateTime(now.year, now.month + 1, targetDay, hour, minute);
          }
        }
        break;

      default:
        nextRun = now.add(const Duration(days: 1));
    }

    return nextRun.toIso8601String();
  }

  static int _dayOfWeekToInt(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  static Future<void> checkAndRunSchedules() async {
    final now = DateTime.now();
    final schedules = getActiveSchedules();

    for (final schedule in schedules) {
      final nextRun = DateTime.tryParse(schedule['nextRun'] ?? '');
      if (nextRun == null) continue;

      if (now.isAfter(nextRun)) {
        await _runScheduledReport(schedule);

        // Update last run and calculate next run
        await updateSchedule(schedule['id'], {
          'lastRun': now.toIso8601String(),
          'nextRun': _calculateNextRun(
            schedule['frequency'],
            schedule['time'],
            schedule['dayOfWeek'],
            schedule['dayOfMonth'],
          ),
        });
      }
    }
  }

  static Future<void> _runScheduledReport(Map<String, dynamic> schedule) async {
    // This would integrate with the report builder to generate and send the report
    // For now, we'll just log that it ran
    LogService.info(
        'Running scheduled report: ${schedule['reportType']} at ${DateTime.now()}');

    // In a real implementation, this would:
    // 1. Generate the report using ReportBuilderScreen logic
    // 2. Export to PDF/CSV
    // 3. Send via email to recipients
    // 4. Store in a reports history
  }

  static String getFrequencyDisplay(
      String frequency, String? dayOfWeek, int? dayOfMonth) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly on ${dayOfWeek ?? "Monday"}';
      case 'monthly':
        return 'Monthly on day ${dayOfMonth ?? 1}';
      default:
        return frequency;
    }
  }

  static String getNextRunDisplay(String? nextRunStr) {
    if (nextRunStr == null) return 'Not scheduled';

    final nextRun = DateTime.tryParse(nextRunStr);
    if (nextRun == null) return 'Invalid date';

    final now = DateTime.now();
    final difference = nextRun.difference(now);

    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? "s" : ""}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? "s" : ""}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? "s" : ""}';
    } else {
      return 'Soon';
    }
  }
}
