// lib/screens/operator_qc_screen.dart
// Simplified QC reporting for operators

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class OperatorQCScreen extends StatefulWidget {
  final String username;
  const OperatorQCScreen({super.key, required this.username});

  @override
  State<OperatorQCScreen> createState() => _OperatorQCScreenState();
}

class _OperatorQCScreenState extends State<OperatorQCScreen> {
  final uuid = const Uuid();
  String _reportType = 'Product'; // 'Product' or 'Machine'
  String? _selectedMachineId;

  @override
  Widget build(BuildContext context) {
    final usersBox = Hive.box('usersBox');
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    final issuesBox = Hive.box('issuesBox');

    // Get operator's assigned machine
    final user = usersBox.values.cast<Map>().firstWhere(
      (u) => u['username'] == widget.username,
      orElse: () => {},
    );
    final assignedMachineId = user['assignedMachineId'] as String?;

    // Get machines to show (assigned or all if no assignment)
    final machines = assignedMachineId != null
        ? machinesBox.values.cast<Map>().where((m) => m['id'] == assignedMachineId).toList()
        : machinesBox.values.cast<Map>().toList();

    // Set default machine
    if (_selectedMachineId == null && machines.isNotEmpty) {
      _selectedMachineId = machines.first['id'] as String;
    }

    // Get running job for selected machine
    final runningJob = _selectedMachineId != null
        ? jobsBox.values.cast<Map?>().firstWhere(
            (j) => j != null && j['machineId'] == _selectedMachineId && j['status'] == 'Running',
            orElse: () => null,
          )
        : null;

    // Get recent issues for this operator
    final myIssues = issuesBox.values.cast<Map>()
        .where((i) => i['reportedBy'] == widget.username)
        .toList()
      ..sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Quality Report'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B6B).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Machine Selection
                  Card(
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
                          const Text(
                            'Select Machine',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedMachineId,
                            dropdownColor: const Color(0xFF0F1419),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.precision_manufacturing, color: Color(0xFF4CC9F0)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4CC9F0)),
                              ),
                            ),
                            items: machines.map((m) => DropdownMenuItem(
                              value: m['id'] as String,
                              child: Text(m['name'] as String),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedMachineId = v),
                          ),
                          if (runningJob != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06D6A0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF06D6A0).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.work, color: Color(0xFF06D6A0), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Currently Running:',
                                          style: TextStyle(fontSize: 11, color: Colors.white54),
                                        ),
                                        Text(
                                          '${runningJob['productName']} • ${runningJob['color'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF06D6A0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Report Type Selection
                  Card(
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
                          const Text(
                            'Report Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'Product',
                                label: Text('Product Defect'),
                                icon: Icon(Icons.inventory_2_outlined),
                              ),
                              ButtonSegment(
                                value: 'Machine',
                                label: Text('Machine Issue'),
                                icon: Icon(Icons.build_outlined),
                              ),
                            ],
                            selected: {_reportType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _reportType = newSelection.first;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Report Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _selectedMachineId != null
                          ? () => _showReportDialog(runningJob)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.report_problem, size: 28),
                      label: Text(
                        'Report ${_reportType == 'Product' ? 'Product Defect' : 'Machine Issue'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // My Recent Reports
                  const Text(
                    'My Recent Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Recent Issues List
          if (myIssues.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No reports yet',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildIssueCard(myIssues[index], machinesBox),
                  childCount: myIssues.length > 10 ? 10 : myIssues.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(Map issue, Box machinesBox) {
    final machine = machinesBox.get(issue['machineId']) as Map?;
    final status = issue['status'] as String? ?? 'Open';
    final priority = issue['priority'] as String? ?? 'Medium';
    final timestamp = DateTime.tryParse(issue['timestamp'] ?? '');

    Color statusColor;
    switch (status) {
      case 'Resolved':
        statusColor = const Color(0xFF06D6A0);
        break;
      case 'In Progress':
        statusColor = const Color(0xFF4CC9F0);
        break;
      default:
        statusColor = const Color(0xFFFF6B6B);
    }

    Color priorityColor;
    switch (priority) {
      case 'Critical':
        priorityColor = const Color(0xFFFF6B6B);
        break;
      case 'High':
        priorityColor = const Color(0xFFFFD166);
        break;
      case 'Medium':
        priorityColor = const Color(0xFF4CC9F0);
        break;
      default:
        priorityColor = const Color(0xFF6C757D);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F1419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (timestamp != null)
                  Text(
                    DateFormat('MMM d, HH:mm').format(timestamp),
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue['title'] ?? 'No title',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (issue['description'] != null && issue['description'] != '') ...[
              const SizedBox(height: 4),
              Text(
                issue['description'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.precision_manufacturing, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  machine?['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(Map? runningJob) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Medium';
    String category = _reportType == 'Product' ? 'Quality' : 'Mechanical';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Report ${_reportType == 'Product' ? 'Product Defect' : 'Machine Issue'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (runningJob != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Job: ${runningJob['productName']} • ${runningJob['color'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Issue Title',
                    hintText: 'Brief description',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    hintText: 'What happened?',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Medium', 'High', 'Critical']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => priority = v ?? 'Medium'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: (_reportType == 'Product'
                          ? ['Quality', 'Contamination', 'Dimension', 'Appearance']
                          : ['Mechanical', 'Electrical', 'Hydraulic', 'Temperature'])
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
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
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                final issuesBox = Hive.box('issuesBox');
                final id = uuid.v4();
                final data = {
                  'id': id,
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'machineId': _selectedMachineId!,
                  'jobId': runningJob?['id'] ?? '',
                  'category': category,
                  'priority': priority,
                  'status': 'Open',
                  'reportedBy': widget.username,
                  'timestamp': DateTime.now().toIso8601String(),
                };

                await issuesBox.put(id, data);
                await SyncService.pushChange('issuesBox', id, data);

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted successfully')),
                  );
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
