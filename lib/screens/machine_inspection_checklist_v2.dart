// lib/screens/machine_inspection_checklist_v2.dart
// Professional Daily Machine Inspection Checklist

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class MachineInspectionChecklistV2 extends StatefulWidget {
  final String username;
  const MachineInspectionChecklistV2({super.key, required this.username});

  @override
  State<MachineInspectionChecklistV2> createState() =>
      _MachineInspectionChecklistV2State();
}

class _MachineInspectionChecklistV2State
    extends State<MachineInspectionChecklistV2> {
  final uuid = const Uuid();
  String? selectedMachineId;
  Map<String, bool> checklistStatus = {};
  Map<String, String> checklistNotes = {};
  bool _isSubmitting = false;

  final inspectionCategories = {
    'Safety': [
      {'id': 'safety_guards', 'name': 'Safety Guards Intact', 'critical': true},
      {'id': 'emergency_stop', 'name': 'Emergency Stop Functional', 'critical': true},
      {'id': 'warning_labels', 'name': 'Warning Labels Visible', 'critical': true},
    ],
    'Mechanical': [
      {'id': 'lubrication', 'name': 'Lubrication Levels', 'critical': true},
      {'id': 'mould_clamps', 'name': 'Mould Clamps Secure', 'critical': true},
      {'id': 'nozzle', 'name': 'Nozzle Condition', 'critical': true},
      {'id': 'oil_level', 'name': 'Machine Oil Level', 'critical': true},
      {'id': 'hydraulic', 'name': 'Hydraulic Pressure', 'critical': true},
      {'id': 'belts_chains', 'name': 'Belts & Chains', 'critical': false},
    ],
    'Process': [
      {'id': 'barrel_temp', 'name': 'Barrel Temperature', 'critical': true},
      {'id': 'cycle_time', 'name': 'Cycle Time Normal', 'critical': false},
      {'id': 'cooling', 'name': 'Cooling System', 'critical': false},
      {'id': 'pressure', 'name': 'Injection Pressure', 'critical': false},
    ],
    'Material': [
      {'id': 'material_level', 'name': 'Material Level Adequate', 'critical': true},
      {'id': 'hopper', 'name': 'Hopper Loader Working', 'critical': false},
      {'id': 'dryer', 'name': 'Material Dryer (if applicable)', 'critical': false},
    ],
    'Documentation': [
      {'id': 'job_card', 'name': 'Job Card Present', 'critical': false},
      {'id': 'production_count', 'name': 'Production Count Verified', 'critical': false},
      {'id': 'logbook', 'name': 'Logbook Updated', 'critical': false},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeChecklist();
  }

  void _initializeChecklist() {
    inspectionCategories.forEach((category, items) {
      for (var item in items) {
        checklistStatus[item['id'] as String] = false;
        checklistNotes[item['id'] as String] = '';
      }
    });
  }

  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen('machinesBox')) {
      await Hive.openBox('machinesBox');
    }
    if (!Hive.isBoxOpen('dailyInspectionsBox')) {
      await Hive.openBox('dailyInspectionsBox');
    }
  }

  Future<bool> _hasCompletedToday(String machineId) async {
    try {
      if (!Hive.isBoxOpen('dailyInspectionsBox')) {
        await Hive.openBox('dailyInspectionsBox');
      }
      final inspectionsBox = Hive.box('dailyInspectionsBox');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final todayInspections = inspectionsBox.values.cast<Map>().where((i) =>
          i['machineId'] == machineId &&
          i['inspectorUsername'] == widget.username &&
          i['date'] == today).toList();
      
      return todayInspections.isNotEmpty;
    } catch (e) {
      print('Error checking inspection status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Daily Machine Inspection'),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Inspector: ${widget.username}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.now()),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Machine Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMachineSelector(),
            ),
          ),

          // Checklist
          if (selectedMachineId != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...inspectionCategories.entries.map((entry) =>
                      _buildCategorySection(entry.key, entry.value)),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMachineSelector() {
    return FutureBuilder(
      future: _ensureBoxesOpen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final machinesBox = Hive.box('machinesBox');
        final machines = machinesBox.values.cast<Map>().toList();
        
        if (machines.isEmpty) {
          return Card(
            color: const Color(0xFF0F1419),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No machines available',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        return Card(
          color: const Color(0xFF0F1419),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF06D6A0), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.precision_manufacturing, color: Color(0xFF06D6A0)),
                    SizedBox(width: 12),
                    Text(
                      'Select Machine to Inspect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...machines.map((machine) {
                  final machineId = machine['id'] as String;
                  return FutureBuilder<bool>(
                    future: _hasCompletedToday(machineId),
                    builder: (context, snapshot) {
                      final isCompleted = snapshot.data ?? false;
                      final isSelected = selectedMachineId == machineId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isCompleted
                                ? null
                                : () => setState(() => selectedMachineId = machineId),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF06D6A0).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF06D6A0)
                                      : isCompleted
                                          ? Colors.green
                                          : Colors.white12,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green.withOpacity(0.2)
                                          : const Color(0xFF06D6A0).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isCompleted ? Icons.check_circle : Icons.factory,
                                      color: isCompleted ? Colors.green : const Color(0xFF06D6A0),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          machine['name'] as String,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        if (isCompleted)
                                          const Text(
                                            'Inspection completed today',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(String category, List<Map<String, dynamic>> items) {
    final completedCount = items.where((item) => checklistStatus[item['id']] == true).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF0F1419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount of $totalCount completed',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
                strokeWidth: 3,
              ),
            ],
          ),
          children: items.map((item) => _buildChecklistItem(item)).toList(),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final isChecked = checklistStatus[itemId] ?? false;
    final isCritical = item['critical'] as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isChecked
            ? const Color(0xFF06D6A0).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked ? const Color(0xFF06D6A0) : Colors.white12,
        ),
      ),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (value) {
          setState(() {
            checklistStatus[itemId] = value ?? false;
          });
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['name'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isCritical)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
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
        subtitle: TextField(
          decoration: const InputDecoration(
            hintText: 'Add notes (optional)',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
            border: InputBorder.none,
            isDense: true,
          ),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          onChanged: (value) {
            checklistNotes[itemId] = value;
          },
        ),
        activeColor: const Color(0xFF06D6A0),
        checkColor: Colors.white,
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      color: const Color(0xFF0F1419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note_alt, color: Color(0xFF4CC9F0)),
                SizedBox(width: 12),
                Text(
                  'Additional Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any additional observations or concerns...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CC9F0)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                checklistNotes['additional'] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final totalItems = checklistStatus.length;
    final completedItems = checklistStatus.values.where((v) => v == true).length;
    final completionRate = totalItems > 0 ? (completedItems / totalItems * 100).round() : 0;

    // Check critical items
    final criticalItems = <String>[];
    inspectionCategories.forEach((category, items) {
      for (var item in items) {
        if (item['critical'] == true) {
          criticalItems.add(item['id'] as String);
        }
      }
    });
    final criticalCompleted = criticalItems.where((id) => checklistStatus[id] == true).length;
    final allCriticalDone = criticalCompleted == criticalItems.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1419),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completion Progress',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '$completionRate%',
                    style: const TextStyle(
                      color: Color(0xFF06D6A0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06D6A0)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    allCriticalDone ? Icons.check_circle : Icons.warning,
                    color: allCriticalDone ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allCriticalDone
                        ? 'All critical items completed'
                        : 'Critical items: $criticalCompleted/${criticalItems.length}',
                    style: TextStyle(
                      color: allCriticalDone ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting || !allCriticalDone ? null : _submitInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06D6A0),
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        allCriticalDone
                            ? 'Submit Inspection ($completionRate% Complete)'
                            : 'Complete Critical Items First',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitInspection() async {
    if (selectedMachineId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final inspectionsBox = await Hive.openBox('dailyInspectionsBox');
      final machinesBox = Hive.box('machinesBox');
      final machine = machinesBox.get(selectedMachineId!) as Map?;

      final inspectionId = uuid.v4();
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);

      final inspectionData = {
        'id': inspectionId,
        'machineId': selectedMachineId,
        'machineName': machine?['name'] ?? 'Unknown',
        'inspectorUsername': widget.username,
        'date': dateKey,
        'timestamp': now.toIso8601String(),
        'checklist': Map<String, dynamic>.from(checklistStatus),
        'notes': Map<String, dynamic>.from(checklistNotes),
        'completionRate': (checklistStatus.values.where((v) => v == true).length /
                checklistStatus.length *
                100)
            .round(),
        'status': 'completed',
      };

      await inspectionsBox.put(inspectionId, inspectionData);
      await SyncService.push('dailyInspectionsBox', inspectionId, inspectionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Inspection completed for ${machine?['name']}'),
              ],
            ),
            backgroundColor: const Color(0xFF06D6A0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Reset for next machine
        setState(() {
          selectedMachineId = null;
          _initializeChecklist();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting inspection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Safety':
        return Colors.red;
      case 'Mechanical':
        return const Color(0xFF06D6A0);
      case 'Process':
        return const Color(0xFF4CC9F0);
      case 'Material':
        return const Color(0xFFFFD166);
      case 'Documentation':
        return const Color(0xFF7209B7);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Safety':
        return Icons.security;
      case 'Mechanical':
        return Icons.build;
      case 'Process':
        return Icons.settings;
      case 'Material':
        return Icons.inventory_2;
      case 'Documentation':
        return Icons.description;
      default:
        return Icons.check_box;
    }
  }
}
