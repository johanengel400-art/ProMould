import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class MouldChangesScreen extends StatefulWidget {
  final int level;
  const MouldChangesScreen({super.key, required this.level});

  @override
  State<MouldChangesScreen> createState() => _MouldChangesScreenState();
}

class _MouldChangesScreenState extends State<MouldChangesScreen> {
  final uuid = const Uuid();

  Future<void> _addMouldChange() async {
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');
    final jobsBox = Hive.box('jobsBox');
    final usersBox = Hive.box('usersBox');

    final machines = machinesBox.values.cast<Map>().toList();
    final moulds = mouldsBox.values.cast<Map>().toList();
    final jobs = jobsBox.values.cast<Map>().toList();
    final setters = usersBox.values.cast<Map>().where((u) => u['level'] == 3).toList();

    String? selectedMachine = machines.isNotEmpty ? machines.first['id'] as String : null;
    String? selectedMould = moulds.isNotEmpty ? moulds.first['id'] as String : null;
    String? selectedJob = jobs.isNotEmpty ? jobs.first['id'] as String : null;
    String? selectedSetter = setters.isNotEmpty ? setters.first['username'] as String : null;
    DateTime scheduledDate = DateTime.now();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Mould Change'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedMachine,
                  items: machines.map((m) => DropdownMenuItem(
                    value: m['id'] as String,
                    child: Text('${m['name']}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedMachine = v),
                  decoration: const InputDecoration(labelText: 'Machine'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMould,
                  items: moulds.map((m) => DropdownMenuItem(
                    value: m['id'] as String,
                    child: Text('${m['name']}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedMould = v),
                  decoration: const InputDecoration(labelText: 'New Mould'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedJob,
                  items: jobs.map((j) => DropdownMenuItem(
                    value: j['id'] as String,
                    child: Text('${j['productName']}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedJob = v),
                  decoration: const InputDecoration(labelText: 'Job'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSetter,
                  items: setters.map((s) => DropdownMenuItem(
                    value: s['username'] as String,
                    child: Text('${s['username']}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedSetter = v),
                  decoration: const InputDecoration(labelText: 'Assign to Setter'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Scheduled Date'),
                  subtitle: Text(DateFormat('MMM d, yyyy HH:mm').format(scheduledDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduledDate),
                      );
                      if (time != null) {
                        setDialogState(() {
                          scheduledDate = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
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
              onPressed: () async {
                final box = Hive.box('mouldChangesBox');
                final id = uuid.v4();
                final data = {
                  'id': id,
                  'machineId': selectedMachine ?? '',
                  'mouldId': selectedMould ?? '',
                  'jobId': selectedJob ?? '',
                  'assignedTo': selectedSetter ?? '',
                  'scheduledDate': scheduledDate.toIso8601String(),
                  'status': 'Pending',
                  'notes': notesCtrl.text.trim(),
                  'createdAt': DateTime.now().toIso8601String(),
                };
                await box.put(id, data);
                await SyncService.pushChange('mouldChangesBox', id, data);
                if (context.mounted) {
                Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _deleteMouldChange(String id) async {
    final box = Hive.box('mouldChangesBox');
    await box.delete(id);
    await SyncService.deleteRemote('mouldChangesBox', id);
    setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('mouldChangesBox');
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');
    final jobsBox = Hive.box('jobsBox');

    final machines = {for (var m in machinesBox.values.cast<Map>()) m['id']: m['name']};
    final moulds = {for (var m in mouldsBox.values.cast<Map>()) m['id']: m['name']};
    final jobs = {for (var j in jobsBox.values.cast<Map>()) j['id']: j['productName']};

    return Scaffold(
      appBar: AppBar(title: const Text('Mould Changes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMouldChange,
        icon: const Icon(Icons.add),
        label: const Text('New Change'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, __, ___) {
          final items = box.values.cast<Map>().toList();
          items.sort((a, b) => (b['scheduledDate'] ?? '').toString().compareTo((a['scheduledDate'] ?? '').toString()));

          if (items.isEmpty) {
            return const Center(
              child: Text('No mould changes scheduled'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final scheduledDate = DateTime.tryParse(item['scheduledDate'] ?? '');
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(item['status'] ?? 'Pending'),
                    child: const Icon(Icons.build, color: Colors.white),
                  ),
                  title: Text('${machines[item['machineId']]} → ${moulds[item['mouldId']]}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Job: ${jobs[item['jobId']]}'),
                      Text('Setter: ${item['assignedTo']}'),
                      if (scheduledDate != null)
                        Text('Scheduled: ${DateFormat('MMM d, yyyy HH:mm').format(scheduledDate)}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteMouldChange(item['id'] as String);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
