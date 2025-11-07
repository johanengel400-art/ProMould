// lib/screens/quality_control_screen.dart
// Quality control and inspection management

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class QualityControlScreen extends StatefulWidget {
  final int level;
  final String username;
  const QualityControlScreen({super.key, required this.level, required this.username});

  @override
  State<QualityControlScreen> createState() => _QualityControlScreenState();
}

class _QualityControlScreenState extends State<QualityControlScreen> {
  final uuid = const Uuid();
  String selectedTab = 'Inspections';

  @override
  void initState() {
    super.initState();
    _initializeBoxes();
  }

  Future<void> _initializeBoxes() async {
    if (!Hive.isBoxOpen('qualityInspectionsBox')) {
      await Hive.openBox('qualityInspectionsBox');
    }
    if (!Hive.isBoxOpen('qualityHoldsBox')) {
      await Hive.openBox('qualityHoldsBox');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeBoxes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            title: const Text('Quality Control'),
            backgroundColor: const Color(0xFF0F1419),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: selectedTab == 'Inspections' ? _addInspection : _addQualityHold,
            icon: const Icon(Icons.add),
            label: Text(selectedTab == 'Inspections' ? 'New Inspection' : 'Quality Hold'),
            backgroundColor: const Color(0xFF4CC9F0),
          ),
          body: Column(
            children: [
              // Tab Selector
              Container(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Inspections',
                      label: Text('Inspections'),
                      icon: Icon(Icons.fact_check),
                    ),
                    ButtonSegment(
                      value: 'Holds',
                      label: Text('Quality Holds'),
                      icon: Icon(Icons.block),
                    ),
                  ],
                  selected: {selectedTab},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => selectedTab = newSelection.first);
                  },
                ),
              ),

              // Content
              Expanded(
                child: selectedTab == 'Inspections'
                    ? _buildInspectionsList()
                    : _buildQualityHoldsList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInspectionsList() {
    final inspectionsBox = Hive.box('qualityInspectionsBox');
    final inspections = inspectionsBox.values.cast<Map>().toList();
    
    inspections.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    if (inspections.isEmpty) {
      return const Center(
        child: Text('No inspections recorded', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inspections.length,
      itemBuilder: (_, i) => _buildInspectionCard(inspections[i]),
    );
  }

  Widget _buildQualityHoldsList() {
    final holdsBox = Hive.box('qualityHoldsBox');
    final holds = holdsBox.values.cast<Map>().where((h) => h['status'] != 'Released').toList();
    
    holds.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    if (holds.isEmpty) {
      return const Center(
        child: Text('No active quality holds', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: holds.length,
      itemBuilder: (_, i) => _buildQualityHoldCard(holds[i]),
    );
  }

  Widget _buildInspectionCard(Map inspection) {
    final result = inspection['result'] as String? ?? 'Pass';
    final resultColor = result == 'Pass' ? const Color(0xFF00D26A) : const Color(0xFFFF6B6B);
    final date = DateTime.tryParse(inspection['date'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            resultColor.withOpacity(0.1),
            const Color(0xFF1A1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            result == 'Pass' ? Icons.check_circle : Icons.cancel,
            color: resultColor,
          ),
        ),
        title: Text(
          inspection['type'] ?? 'Inspection',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Job: ${inspection['jobId'] ?? 'N/A'}'),
            Text('Inspector: ${inspection['inspector'] ?? 'Unknown'}'),
            Text(DateFormat('MMM d, yyyy HH:mm').format(date)),
            if (inspection['notes'] != null && (inspection['notes'] as String).isNotEmpty)
              Text(
                inspection['notes'] as String,
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: resultColor),
          ),
          child: Text(
            result,
            style: TextStyle(color: resultColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityHoldCard(Map hold) {
    final severity = hold['severity'] as String? ?? 'Medium';
    final severityColor = _getSeverityColor(severity);
    final date = DateTime.tryParse(hold['date'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            severityColor.withOpacity(0.1),
            const Color(0xFF1A1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.block, color: severityColor),
            ),
            title: Text(
              hold['reason'] ?? 'Quality Hold',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Job: ${hold['jobId'] ?? 'N/A'}'),
                Text('Quantity: ${hold['quantity'] ?? 0} units'),
                Text(DateFormat('MMM d, yyyy HH:mm').format(date)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: severityColor),
              ),
              child: Text(
                severity,
                style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _releaseHold(hold),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Release'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00D26A),
                      side: const BorderSide(color: Color(0xFF00D26A)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scrapHold(hold),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Scrap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: const BorderSide(color: Color(0xFFFF6B6B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addInspection() async {
    final jobsBox = Hive.box('jobsBox');
    final jobs = jobsBox.values.cast<Map>().where((j) => j['status'] == 'Running').toList();

    if (jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No running jobs to inspect')),
      );
      return;
    }

    String? selectedJobId = jobs.first['id'] as String;
    String inspectionType = 'First Article';
    String result = 'Pass';
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Inspection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedJobId,
                  decoration: const InputDecoration(labelText: 'Job'),
                  items: jobs.map((j) => DropdownMenuItem(
                    value: j['id'] as String,
                    child: Text(j['productName'] as String),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedJobId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: inspectionType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['First Article', 'In-Process', 'Final', 'Random'].map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => inspectionType = v ?? 'First Article'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: result,
                  decoration: const InputDecoration(labelText: 'Result'),
                  items: ['Pass', 'Fail'].map((r) =>
                    DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => result = v ?? 'Pass'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final inspectionsBox = Hive.box('qualityInspectionsBox');
                final id = uuid.v4();
                final data = {
                  'id': id,
                  'jobId': selectedJobId,
                  'type': inspectionType,
                  'result': result,
                  'inspector': widget.username,
                  'notes': notesCtrl.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                };
                await inspectionsBox.put(id, data);
                await SyncService.push('qualityInspectionsBox', id, data);
                if (context.mounted) {
                Navigator.pop(dialogContext);
                }
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addQualityHold() async {
    final jobsBox = Hive.box('jobsBox');
    final jobs = jobsBox.values.cast<Map>().where((j) => j['status'] == 'Running').toList();

    if (jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No running jobs')),
      );
      return;
    }

    String? selectedJobId = jobs.first['id'] as String;
    String severity = 'Medium';
    final reasonCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Quality Hold'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedJobId,
                  decoration: const InputDecoration(labelText: 'Job'),
                  items: jobs.map((j) => DropdownMenuItem(
                    value: j['id'] as String,
                    child: Text(j['productName'] as String),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedJobId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: ['Low', 'Medium', 'High', 'Critical'].map((s) =>
                    DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => severity = v ?? 'Medium'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final holdsBox = Hive.box('qualityHoldsBox');
                final id = uuid.v4();
                final data = {
                  'id': id,
                  'jobId': selectedJobId,
                  'reason': reasonCtrl.text.trim(),
                  'quantity': int.tryParse(quantityCtrl.text) ?? 0,
                  'severity': severity,
                  'status': 'Active',
                  'createdBy': widget.username,
                  'date': DateTime.now().toIso8601String(),
                };
                await holdsBox.put(id, data);
                await SyncService.push('qualityHoldsBox', id, data);
                if (context.mounted) {
                Navigator.pop(dialogContext);
                }
                setState(() {});
              },
              child: const Text('Create Hold'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _releaseHold(Map hold) async {
    final holdsBox = Hive.box('qualityHoldsBox');
    final id = hold['id'] as String;
    final updated = Map<String, dynamic>.from(hold);
    updated['status'] = 'Released';
    updated['releasedBy'] = widget.username;
    updated['releasedAt'] = DateTime.now().toIso8601String();
    await holdsBox.put(id, updated);
    await SyncService.push('qualityHoldsBox', id, updated);
    setState(() {});
  }

  Future<void> _scrapHold(Map hold) async {
    final holdsBox = Hive.box('qualityHoldsBox');
    final id = hold['id'] as String;
    final updated = Map<String, dynamic>.from(hold);
    updated['status'] = 'Scrapped';
    updated['scrappedBy'] = widget.username;
    updated['scrappedAt'] = DateTime.now().toIso8601String();
    await holdsBox.put(id, updated);
    await SyncService.push('qualityHoldsBox', id, updated);
    setState(() {});
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFFF6B6B);
      case 'High':
        return const Color(0xFFFF9500);
      case 'Medium':
        return const Color(0xFFFFD166);
      case 'Low':
        return const Color(0xFF80ED99);
      default:
        return const Color(0xFF6C757D);
    }
  }
}
