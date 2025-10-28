// lib/screens/machine_inspection_checklist_screen.dart
// Enhanced Machine Inspection Checklist for Setters

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class MachineInspectionChecklistScreen extends StatefulWidget {
  final int level;
  final String username;
  const MachineInspectionChecklistScreen({
    super.key,
    required this.level,
    required this.username,
  });

  @override
  State<MachineInspectionChecklistScreen> createState() =>
      _MachineInspectionChecklistScreenState();
}

class _MachineInspectionChecklistScreenState
    extends State<MachineInspectionChecklistScreen> {
  final uuid = const Uuid();
  DateTime selectedDate = DateTime.now();
  String _viewMode = 'checklist'; // 'checklist' or 'history'

  final inspectionItems = [
    {'name': 'Check Lubrication', 'category': 'Mechanical', 'critical': true},
    {'name': 'Check Mould Clamps', 'category': 'Mechanical', 'critical': true},
    {'name': 'Check Cycle Time', 'category': 'Process', 'critical': false},
    {'name': 'Check Material Level', 'category': 'Material', 'critical': true},
    {'name': 'Check Job Card', 'category': 'Documentation', 'critical': false},
    {'name': 'Check Nozzle Condition', 'category': 'Mechanical', 'critical': true},
    {'name': 'Check Barrel Temperature', 'category': 'Process', 'critical': true},
    {'name': 'Check Hopper Loader', 'category': 'Material', 'critical': false},
    {'name': 'Check Machine Oil Level', 'category': 'Mechanical', 'critical': true},
    {'name': 'Check Hydraulic Pressure', 'category': 'Mechanical', 'critical': true},
    {'name': 'Check Safety Guards', 'category': 'Safety', 'critical': true},
    {'name': 'Check Emergency Stop', 'category': 'Safety', 'critical': true},
    {'name': 'Check Cooling System', 'category': 'Process', 'critical': false},
    {'name': 'Verify Production Count', 'category': 'Production', 'critical': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_viewMode == 'checklist')
            _buildChecklistView()
          else
            _buildHistoryView(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F1419),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Machine Inspections'),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF06D6A0).withOpacity(0.3),
                const Color(0xFF0F1419),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_viewMode == 'checklist' ? Icons.history : Icons.checklist),
          onPressed: () {
            setState(() {
              _viewMode = _viewMode == 'checklist' ? 'history' : 'checklist';
            });
          },
        ),
      ],
    );
  }

  Widget _buildChecklistView() {
    final usersBox = Hive.box('usersBox');
    final user = usersBox.values.cast<Map>().firstWhere(
          (u) => u['username'] == widget.username,
          orElse: () => {},
        );

    final assignedFloorId = user['assignedFloorId'] as String?;
    final machinesBox = Hive.box('machinesBox');

    // Get machines for setter's floor
    final machines = machinesBox.values.cast<Map>().where((m) {
      if (assignedFloorId == null) return true;
      return m['floorId'] == assignedFloorId;
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMachineCard(machines[index]),
          childCount: machines.length,
        ),
      ),
    );
  }

  Widget _buildMachineCard(Map machine) {
    final machineId = machine['id'] as String;
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    return FutureBuilder(
      future: _getInspectionStatus(machineId, dateKey),
      builder: (context, snapshot) {
        final inspectionData = snapshot.data;
        final isComplete = inspectionData?['isComplete'] ?? false;
        final completionPercent = inspectionData?['completionPercent'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF0F1419),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isComplete
                  ? const Color(0xFF06D6A0)
                  : Colors.white12,
              width: isComplete ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showInspectionDialog(machine),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isComplete
                              ? const Color(0xFF06D6A0).withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isComplete ? Icons.check_circle : Icons.pending,
                          color: isComplete
                              ? const Color(0xFF06D6A0)
                              : Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              machine['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${machine['tonnage'] ?? ''}T',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$completionPercent%',
                            style: TextStyle(
                              color: isComplete
                                  ? const Color(0xFF06D6A0)
                                  : Colors.orange,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isComplete ? 'Complete' : 'Pending',
                            style: TextStyle(
                              color: isComplete
                                  ? const Color(0xFF06D6A0)
                                  : Colors.orange,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isComplete) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completionPercent / 100,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getInspectionStatus(
      String machineId, String dateKey) async {
    final inspectionsBox = Hive.box('machineInspectionsBox');
    final key = '${machineId}_$dateKey';
    final inspection = inspectionsBox.get(key) as Map?;

    if (inspection == null) {
      return {'isComplete': false, 'completionPercent': 0};
    }

    final checks = inspection['checks'] as Map? ?? {};
    final total = inspectionItems.length;
    final completed = checks.values.where((v) => v == true).length;
    final percent = ((completed / total) * 100).round();

    return {
      'isComplete': completed == total,
      'completionPercent': percent,
    };
  }

  void _showInspectionDialog(Map machine) {
    final machineId = machine['id'] as String;
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final key = '${machineId}_$dateKey';

    showDialog(
      context: context,
      builder: (context) => _InspectionDialog(
        machine: machine,
        inspectionKey: key,
        inspectionItems: inspectionItems,
        username: widget.username,
        onComplete: () => setState(() {}),
      ),
    );
  }

  Widget _buildHistoryView() {
    final inspectionsBox = Hive.box('machineInspectionsBox');

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: ValueListenableBuilder(
        valueListenable: inspectionsBox.listenable(),
        builder: (context, box, _) {
          final inspections = box.values.cast<Map>().toList()
            ..sort((a, b) =>
                (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

          if (inspections.isEmpty) {
            return const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No inspection history',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildHistoryCard(inspections[index]),
              childCount: inspections.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map inspection) {
    final timestamp = DateTime.tryParse(inspection['timestamp'] ?? '');
    final machinesBox = Hive.box('machinesBox');
    final machine = machinesBox.get(inspection['machineId']) as Map?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F1419),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Color(0xFF06D6A0)),
        title: Text(
          machine?['name'] ?? 'Unknown Machine',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          timestamp != null
              ? DateFormat('MMM d, yyyy HH:mm').format(timestamp)
              : 'Unknown date',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Text(
          inspection['completedBy'] ?? '',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }
}

class _InspectionDialog extends StatefulWidget {
  final Map machine;
  final String inspectionKey;
  final List<Map<String, dynamic>> inspectionItems;
  final String username;
  final VoidCallback onComplete;

  const _InspectionDialog({
    required this.machine,
    required this.inspectionKey,
    required this.inspectionItems,
    required this.username,
    required this.onComplete,
  });

  @override
  State<_InspectionDialog> createState() => _InspectionDialogState();
}

class _InspectionDialogState extends State<_InspectionDialog> {
  late Map<String, bool> checks;
  late Map<String, String> notes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspection();
  }

  Future<void> _loadInspection() async {
    final inspectionsBox = Hive.box('machineInspectionsBox');
    final existing = inspectionsBox.get(widget.inspectionKey) as Map?;

    if (existing != null) {
      checks = Map<String, bool>.from(existing['checks'] ?? {});
      notes = Map<String, String>.from(existing['notes'] ?? {});
    } else {
      checks = {for (var item in widget.inspectionItems) item['name']: false};
      notes = {};
    }

    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final inspectionsBox = Hive.box('machineInspectionsBox');
    final data = {
      'machineId': widget.machine['id'],
      'machineName': widget.machine['name'],
      'checks': checks,
      'notes': notes,
      'completedBy': widget.username,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await inspectionsBox.put(widget.inspectionKey, data);
    await SyncService.pushChange(
        'machineInspectionsBox', widget.inspectionKey, data);

    if (mounted) {
      Navigator.pop(context);
      widget.onComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection saved'),
          backgroundColor: Color(0xFF06D6A0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        backgroundColor: Color(0xFF0F1419),
        content: Center(child: CircularProgressIndicator()),
      );
    }

    final completed = checks.values.where((v) => v == true).length;
    final total = checks.length;
    final percent = ((completed / total) * 100).round();

    return AlertDialog(
      backgroundColor: const Color(0xFF0F1419),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.machine['name'] ?? 'Machine Inspection'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF06D6A0),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Color(0xFF06D6A0),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.inspectionItems.length,
          itemBuilder: (context, index) {
            final item = widget.inspectionItems[index];
            final itemName = item['name'] as String;
            final isCritical = item['critical'] as bool;

            return Card(
              color: const Color(0xFF1A1F2E),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: checks[itemName] ?? false,
                    onChanged: (v) {
                      setState(() => checks[itemName] = v ?? false);
                    },
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        if (isCritical)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CRITICAL',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      item['category'] as String,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    activeColor: const Color(0xFF06D6A0),
                  ),
                  if (checks[itemName] == false) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add note (optional)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (v) => notes[itemName] = v,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06D6A0),
          ),
          child: const Text('Save Inspection'),
        ),
      ],
    );
  }
}
