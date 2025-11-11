import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/scheduled_reports_service.dart';

class ScheduledReportsScreen extends StatefulWidget {
  const ScheduledReportsScreen({super.key});

  @override
  State<ScheduledReportsScreen> createState() => _ScheduledReportsScreenState();
}

class _ScheduledReportsScreenState extends State<ScheduledReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Scheduled Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateScheduleDialog(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('scheduledReportsBox').listenable(),
        builder: (context, box, _) {
          final schedules = ScheduledReportsService.getAllSchedules();

          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  const Text(
                    'No scheduled reports',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to create your first schedule',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _buildScheduleCard(schedule);
            },
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final isActive = schedule['isActive'] as bool;
    final nextRun = schedule['nextRun'] as String?;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getReportTypeDisplay(schedule['reportType']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ScheduledReportsService.getFrequencyDisplay(
                          schedule['frequency'],
                          schedule['dayOfWeek'],
                          schedule['dayOfMonth'],
                        ),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    ScheduledReportsService.toggleSchedule(
                        schedule['id'], value);
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${schedule['time']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Next run: ${ScheduledReportsService.getNextRunDisplay(nextRun)}',
                        style: TextStyle(
                          color: isActive ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (schedule['recipients'] != null &&
                      (schedule['recipients'] as List).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recipients: ${(schedule['recipients'] as List).join(", ")}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditScheduleDialog(schedule),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(schedule['id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getReportTypeDisplay(String type) {
    switch (type) {
      case 'production':
        return 'Production Report';
      case 'quality':
        return 'Quality Report';
      case 'downtime':
        return 'Downtime Report';
      case 'machine':
        return 'Machine Performance Report';
      case 'operator':
        return 'Operator Performance Report';
      default:
        return type;
    }
  }

  void _showCreateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => const _ScheduleDialog(),
    );
  }

  void _showEditScheduleDialog(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(schedule: schedule),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Schedule',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this scheduled report?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ScheduledReportsService.deleteSchedule(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  final Map<String, dynamic>? schedule;

  const _ScheduleDialog({this.schedule});

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late String _reportType;
  late String _frequency;
  late TimeOfDay _time;
  String? _dayOfWeek;
  int? _dayOfMonth;
  final _recipientsController = TextEditingController();
  bool _includeCharts = true;
  bool _includeSummary = true;
  bool _includeDetails = true;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _reportType = widget.schedule!['reportType'];
      _frequency = widget.schedule!['frequency'];
      final timeParts = (widget.schedule!['time'] as String).split(':');
      _time = TimeOfDay(
          hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      _dayOfWeek = widget.schedule!['dayOfWeek'];
      _dayOfMonth = widget.schedule!['dayOfMonth'];
      _recipientsController.text =
          (widget.schedule!['recipients'] as List).join(', ');
      _includeCharts = widget.schedule!['includeCharts'] ?? true;
      _includeSummary = widget.schedule!['includeSummary'] ?? true;
      _includeDetails = widget.schedule!['includeDetails'] ?? true;
    } else {
      _reportType = 'production';
      _frequency = 'daily';
      _time = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        widget.schedule == null ? 'Create Schedule' : 'Edit Schedule',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _reportType,
              decoration: const InputDecoration(
                labelText: 'Report Type',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: const Color(0xFF2D2D2D),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                    value: 'production', child: Text('Production')),
                DropdownMenuItem(value: 'quality', child: Text('Quality')),
                DropdownMenuItem(value: 'downtime', child: Text('Downtime')),
                DropdownMenuItem(
                    value: 'machine', child: Text('Machine Performance')),
                DropdownMenuItem(
                    value: 'operator', child: Text('Operator Performance')),
              ],
              onChanged: (value) => setState(() => _reportType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: const Color(0xFF2D2D2D),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            const SizedBox(height: 16),
            if (_frequency == 'weekly')
              DropdownButtonFormField<String>(
                value: _dayOfWeek ?? 'Monday',
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                dropdownColor: const Color(0xFF2D2D2D),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                  DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                  DropdownMenuItem(
                      value: 'Wednesday', child: Text('Wednesday')),
                  DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                  DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                  DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                  DropdownMenuItem(value: 'Sunday', child: Text('Sunday')),
                ],
                onChanged: (value) => setState(() => _dayOfWeek = value),
              ),
            if (_frequency == 'monthly')
              DropdownButtonFormField<int>(
                value: _dayOfMonth ?? 1,
                decoration: const InputDecoration(
                  labelText: 'Day of Month',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                dropdownColor: const Color(0xFF2D2D2D),
                style: const TextStyle(color: Colors.white),
                items: List.generate(31, (i) => i + 1)
                    .map((day) => DropdownMenuItem(
                        value: day, child: Text(day.toString())))
                    .toList(),
                onChanged: (value) => setState(() => _dayOfMonth = value),
              ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Time', style: TextStyle(color: Colors.grey)),
              subtitle: Text(
                _time.format(context),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: const Icon(Icons.access_time, color: Colors.blue),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) {
                  setState(() => _time = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientsController,
              decoration: const InputDecoration(
                labelText: 'Recipients (comma-separated emails)',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'email1@example.com, email2@example.com',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include Summary',
                  style: TextStyle(color: Colors.white)),
              value: _includeSummary,
              onChanged: (value) =>
                  setState(() => _includeSummary = value ?? true),
              activeColor: Colors.blue,
            ),
            CheckboxListTile(
              title: const Text('Include Charts',
                  style: TextStyle(color: Colors.white)),
              value: _includeCharts,
              onChanged: (value) =>
                  setState(() => _includeCharts = value ?? true),
              activeColor: Colors.blue,
            ),
            CheckboxListTile(
              title: const Text('Include Details',
                  style: TextStyle(color: Colors.white)),
              value: _includeDetails,
              onChanged: (value) =>
                  setState(() => _includeDetails = value ?? true),
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() async {
    final recipients = _recipientsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (widget.schedule == null) {
      await ScheduledReportsService.createSchedule(
        reportType: _reportType,
        frequency: _frequency,
        time:
            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        dayOfWeek: _dayOfWeek,
        dayOfMonth: _dayOfMonth,
        recipients: recipients,
        includeCharts: _includeCharts,
        includeSummary: _includeSummary,
        includeDetails: _includeDetails,
      );
    } else {
      await ScheduledReportsService.updateSchedule(widget.schedule!['id'], {
        'reportType': _reportType,
        'frequency': _frequency,
        'time':
            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        'dayOfWeek': _dayOfWeek,
        'dayOfMonth': _dayOfMonth,
        'recipients': recipients,
        'includeCharts': _includeCharts,
        'includeSummary': _includeSummary,
        'includeDetails': _includeDetails,
      });
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _recipientsController.dispose();
    super.dispose();
  }
}
