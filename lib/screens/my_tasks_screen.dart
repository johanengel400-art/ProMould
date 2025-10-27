// lib/screens/my_tasks_screen.dart
// Setter-specific task view

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class MyTasksScreen extends StatefulWidget {
  final String username;
  final int level;
  const MyTasksScreen({super.key, required this.username, required this.level});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: Text('My Tasks - ${widget.username}'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMouldChangesSection(),
          const SizedBox(height: 16),
          _buildChecklistsSection(),
          const SizedBox(height: 16),
          _buildIssuesSection(),
        ],
      ),
    );
  }

  Widget _buildMouldChangesSection() {
    if (!Hive.isBoxOpen('mouldChangesBox')) {
      return const SizedBox.shrink();
    }
    
    final mouldChangesBox = Hive.box('mouldChangesBox');
    final myChanges = mouldChangesBox.values.cast<Map>().where((c) =>
        c['assignedTo'] == widget.username &&
        (c['status'] == 'Scheduled' || c['status'] == 'In Progress')).toList();
    
    myChanges.sort((a, b) {
      final aDate = DateTime.tryParse(a['scheduledDate'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['scheduledDate'] ?? '') ?? DateTime.now();
      return aDate.compareTo(bDate);
    });

    return _buildSection(
      'Mould Changes',
      Icons.swap_horiz,
      const Color(0xFF4CC9F0),
      myChanges.length,
      myChanges.isEmpty
          ? const Text('No mould changes assigned', style: TextStyle(color: Colors.white54))
          : Column(
              children: myChanges.map((change) => _buildMouldChangeCard(change)).toList(),
            ),
    );
  }

  Widget _buildChecklistsSection() {
    if (!Hive.isBoxOpen('checklistsBox')) {
      return const SizedBox.shrink();
    }
    
    final checklistsBox = Hive.box('checklistsBox');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final myChecklists = checklistsBox.values.cast<Map>().where((c) =>
        c['date'] == today &&
        c['setter'] == widget.username &&
        c['completed'] != true).toList();

    return _buildSection(
      'Today\'s Checklists',
      Icons.checklist,
      const Color(0xFF80ED99),
      myChecklists.length,
      myChecklists.isEmpty
          ? const Text('No checklist items for today', style: TextStyle(color: Colors.white54))
          : Column(
              children: myChecklists.map((item) => _buildChecklistCard(item)).toList(),
            ),
    );
  }

  Widget _buildIssuesSection() {
    final issuesBox = Hive.box('issuesBox');
    final myIssues = issuesBox.values.cast<Map>().where((i) =>
        i['reportedBy'] == widget.username &&
        i['status'] != 'Resolved').toList();
    
    myIssues.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return _buildSection(
      'My Open Issues',
      Icons.report_problem,
      const Color(0xFFFFD166),
      myIssues.length,
      myIssues.isEmpty
          ? const Text('No open issues', style: TextStyle(color: Colors.white54))
          : Column(
              children: myIssues.take(5).map((issue) => _buildIssueCard(issue)).toList(),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, int count, Widget content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            const Color(0xFF1A1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildMouldChangeCard(Map change) {
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');
    
    final machine = machinesBox.get(change['machineId']) as Map?;
    final toMould = mouldsBox.get(change['toMouldId']) as Map?;
    final scheduledDate = DateTime.tryParse(change['scheduledDate'] ?? '') ?? DateTime.now();
    final isOverdue = scheduledDate.isBefore(DateTime.now());
    final status = change['status'] as String? ?? 'Scheduled';
    final statusColor = status == 'In Progress' ? const Color(0xFF4CC9F0) : const Color(0xFFFFD166);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFF6B6B) : statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  machine?['name'] ?? 'Unknown Machine',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To: ${toMould?['number'] ?? 'N/A'} - ${toMould?['name'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, HH:mm').format(scheduledDate),
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white60,
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: 8),
                const Text(
                  'OVERDUE',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(Map item) {
    final priority = item['priority'] as String? ?? 'Normal';
    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_box_outline_blank, color: priorityColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (item['description'] != null && (item['description'] as String).isNotEmpty)
                  Text(
                    item['description'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priority,
              style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(Map issue) {
    final severity = issue['severity'] as String? ?? 'Medium';
    final severityColor = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  issue['description'] ?? 'No description',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity,
                  style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${issue['status'] ?? 'Open'}',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return const Color(0xFFFF6B6B);
      case 'High':
        return const Color(0xFFFF9500);
      case 'Normal':
        return const Color(0xFF80ED99);
      case 'Low':
        return const Color(0xFF4CC9F0);
      default:
        return const Color(0xFF6C757D);
    }
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
