// lib/screens/machine_inspection_screen.dart
// v7.3 – Machine Daily Inspection Sheet (Weekly View)

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class MachineInspectionScreen extends StatefulWidget {
  final int level;
  const MachineInspectionScreen({super.key, required this.level});

  @override
  State<MachineInspectionScreen> createState() => _MachineInspectionScreenState();
}

class _MachineInspectionScreenState extends State<MachineInspectionScreen> {
  final uuid = const Uuid();
  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final areaCtrl = TextEditingController();
  final shiftCtrl = TextEditingController();
  final machineCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final addRemarksCtrl = TextEditingController();

  final days = ['Mon', 'Tues', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];
  final checks = [
    'Check Lubrication',
    'Check Mould Clamps',
    'Check Cycle Time',
    'Check Material',
    'Check Job Card',
    'Check Nozzle',
    'Check Temperature on Barrel',
    'Check Hopper Loader',
    'Check Machine Oil Level',
    'Production',
    'Signature'
  ];

  // Create a 2D map for [check][day]
  late Map<String, Map<String, bool>> status;

  @override
  void initState() {
    super.initState();
    status = {
      for (var c in checks)
        c: {for (var d in days) d: false}
    };
  }

  Future<void> _save() async {
    final data = {
      'id': uuid.v4(),
      'name': nameCtrl.text.trim(),
      'area': areaCtrl.text.trim(),
      'shift': shiftCtrl.text.trim(),
      'machineNo': machineCtrl.text.trim(),
      'date': DateTime.now().toIso8601String(),
      'status': status,
      'remarks': remarksCtrl.text.trim(),
      'addRemarks': addRemarksCtrl.text.trim(),
    };

    final box = await Hive.openBox('inspectionsBox');
    await box.add(data);
    await SyncService.push('inspectionsBox', data['id'], data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspection sheet saved successfully')),
    );
    _resetForm();
  }

  void _resetForm() {
    areaCtrl.clear();
    shiftCtrl.clear();
    machineCtrl.clear();
    remarksCtrl.clear();
    addRemarksCtrl.clear();
    _initializeStatus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Machine Daily Inspection Sheet'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Name & Surname', nameCtrl,
                  rightLabel: 'Area', rightCtrl: areaCtrl),
              _infoRow('Shift', shiftCtrl,
                  rightLabel: 'Machine No', rightCtrl: machineCtrl),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              _weeklyChecklistTable(),
              const SizedBox(height: 20),
              TextFormField(
                controller: remarksCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: addRemarksCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Additional Remarks',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Inspection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06D6A0),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String leftLabel, TextEditingController leftCtrl,
      {String? rightLabel, TextEditingController? rightCtrl}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: leftCtrl,
              style: const TextStyle(color: Colors.white),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter $leftLabel' : null,
              decoration: InputDecoration(
                labelText: leftLabel,
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF06D6A0)),
                ),
              ),
            ),
          ),
          if (rightLabel != null && rightCtrl != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: rightCtrl,
                style: const TextStyle(color: Colors.white),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter $rightLabel' : null,
                decoration: InputDecoration(
                  labelText: rightLabel,
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF06D6A0)),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _weeklyChecklistTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            MaterialStateProperty.all(const Color(0xFF06D6A0).withOpacity(0.2)),
        border: TableBorder.all(color: Colors.grey.shade600),
        columns: [
          const DataColumn(
            label: Text(
              'Inspection Point',
              style: TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.bold),
            ),
          ),
          ...days.map((d) => DataColumn(
            label: Text(
              d,
              style: const TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.bold),
            ),
          )),
        ],
        rows: checks.map((c) {
          return DataRow(
            cells: [
              DataCell(Text(c, style: const TextStyle(color: Colors.white))),
              ...days.map((d) => DataCell(
                    Checkbox(
                      value: status[c]![d],
                      onChanged: (v) {
                        setState(() => status[c]![d] = v ?? false);
                      },
                      activeColor: const Color(0xFF06D6A0),
                    ),
                  )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
