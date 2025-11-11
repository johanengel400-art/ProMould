import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/photo_service.dart';
import '../services/sync_service.dart';

class IssuesScreenV2 extends StatefulWidget {
  final String username;
  final int level;
  const IssuesScreenV2(
      {super.key, required this.username, required this.level});
  @override
  State<IssuesScreenV2> createState() => _IssuesScreenV2State();
}

class _IssuesScreenV2State extends State<IssuesScreenV2> {
  final uuid = const Uuid();
  String _filterStatus = 'All';
  String _filterPriority = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final issuesBox = Hive.box('issuesBox');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Issues & Defects'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF476F).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStatsCards(issuesBox),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFilters(),
            ),
          ),

          // Issues List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: ValueListenableBuilder(
              valueListenable: issuesBox.listenable(),
              builder: (context, box, _) {
                var items = issuesBox.values.cast<Map>().toList();

                // Apply filters
                if (_filterStatus != 'All') {
                  items =
                      items.where((i) => i['status'] == _filterStatus).toList();
                }
                if (_filterPriority != 'All') {
                  items = items
                      .where((i) => i['priority'] == _filterPriority)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  items = items
                      .where((i) =>
                          (i['title']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ??
                              false) ||
                          (i['description']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ??
                              false))
                      .toList();
                }

                // Sort by timestamp (newest first)
                items.sort((a, b) =>
                    (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            'No issues found',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildIssueCard(items[index]),
                    childCount: items.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: const Color(0xFFEF476F),
        icon: const Icon(Icons.add),
        label: const Text('New Issue'),
      ),
    );
  }

  Widget _buildStatsCards(Box issuesBox) {
    final items = issuesBox.values.cast<Map>().toList();
    final open = items.where((i) => i['status'] == 'Open').length;
    final inProgress = items.where((i) => i['status'] == 'In Progress').length;
    final resolved = items.where((i) => i['status'] == 'Resolved').length;
    final critical = items.where((i) => i['priority'] == 'Critical').length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Open', open.toString(),
                const Color(0xFFFFD166), Icons.error_outline)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('In Progress', inProgress.toString(),
                const Color(0xFF4CC9F0), Icons.pending_outlined)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Resolved', resolved.toString(),
                const Color(0xFF06D6A0), Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Critical', critical.toString(),
                const Color(0xFFEF476F), Icons.warning_outlined)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), const Color(0xFF0F1419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Search
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search issues...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F1419),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips
        Row(
          children: [
            Expanded(
              child: _buildFilterChip(
                'Status',
                _filterStatus,
                ['All', 'Open', 'In Progress', 'Resolved', 'Closed'],
                (value) => setState(() => _filterStatus = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterChip(
                'Priority',
                _filterPriority,
                ['All', 'Low', 'Medium', 'High', 'Critical'],
                (value) => setState(() => _filterPriority = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, List<String> options,
      Function(String) onChanged) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1419),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label: $value',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(value: option, child: Text(option));
      }).toList(),
    );
  }

  Widget _buildIssueCard(Map issue) {
    final status = issue['status'] ?? 'Open';
    final priority = issue['priority'] ?? 'Medium';
    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F1419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white12),
      ),
      child: InkWell(
        onTap: () => _showIssueDetails(context, issue),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: priorityColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white38),
                    onPressed: () => _showOptionsMenu(context, issue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                issue['title'] ?? 'Untitled Issue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                issue['description'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    issue['reportedBy'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(issue['timestamp']),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  if (issue['photoUrl'] != null &&
                      (issue['photoUrl'] as String).isNotEmpty) ...[
                    const Spacer(),
                    Icon(Icons.image, size: 16, color: Colors.white38),
                  ],
                  if (issue['assignedTo'] != null &&
                      (issue['assignedTo'] as String).isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.assignment_ind, size: 14, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      issue['assignedTo'],
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ],
              ),

              // Resolution Info or Button
              if (status == 'Resolved' || status == 'Closed') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06D6A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF06D6A0).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF06D6A0), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Resolved by ${issue['resolvedBy'] ?? 'Unknown'}',
                            style: const TextStyle(
                              color: Color(0xFF06D6A0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (issue['resolvedAt'] != null)
                            Text(
                              _formatTimestamp(issue['resolvedAt']),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                        ],
                      ),
                      if (issue['resolutionAction'] != null &&
                          (issue['resolutionAction'] as String).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Action: ${issue['resolutionAction']}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (issue['resolutionNextSteps'] != null &&
                          (issue['resolutionNextSteps'] as String)
                              .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Next: ${issue['resolutionNextSteps']}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (widget.level >= 2) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showResolveDialog(issue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06D6A0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Resolve Issue'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFFFFD166);
      case 'In Progress':
        return const Color(0xFF4CC9F0);
      case 'Resolved':
        return const Color(0xFF06D6A0);
      case 'Closed':
        return Colors.white38;
      default:
        return Colors.white70;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return const Color(0xFF06D6A0);
      case 'Medium':
        return const Color(0xFFFFD166);
      case 'High':
        return const Color(0xFFFF8C42);
      case 'Critical':
        return const Color(0xFFEF476F);
      default:
        return Colors.white70;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dt);
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAddEditDialog(BuildContext context, [Map? issue]) {
    final isEdit = issue != null;
    final titleCtrl = TextEditingController(text: issue?['title'] ?? '');
    final descCtrl = TextEditingController(text: issue?['description'] ?? '');
    String priority = issue?['priority'] ?? 'Medium';
    String status = issue?['status'] ?? 'Open';
    String assignedTo = issue?['assignedTo'] ?? '';
    String? photoUrl = issue?['photoUrl'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F1419),
          title: Text(isEdit ? 'Edit Issue' : 'New Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: const Color(0xFF0F1419),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: ['Low', 'Medium', 'High', 'Critical'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => priority = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: const Color(0xFF0F1419),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: ['Open', 'In Progress', 'Resolved', 'Closed'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => assignedTo = value,
                  controller: TextEditingController(text: assignedTo),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Assigned To (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final id = uuid.v4();
                        final url = await PhotoService.captureAndUpload(id);
                        if (url != null) setDialogState(() => photoUrl = url);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final id = uuid.v4();
                        final url = await PhotoService.chooseAndUpload(id);
                        if (url != null) setDialogState(() => photoUrl = url);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                if (photoUrl != null && photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Photo attached',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
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
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                final issuesBox = Hive.box('issuesBox');
                final id = issue?['id'] ?? uuid.v4();
                final data = {
                  'id': id,
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'priority': priority,
                  'status': status,
                  'assignedTo': assignedTo,
                  'photoUrl': photoUrl ?? '',
                  'reportedBy': issue?['reportedBy'] ?? widget.username,
                  'timestamp':
                      issue?['timestamp'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                await issuesBox.put(id, data);
                await SyncService.pushChange('issuesBox', id, data);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(isEdit ? 'Issue updated' : 'Issue created')),
                  );
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(BuildContext context, Map issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1419),
        title: Row(
          children: [
            Expanded(child: Text(issue['title'] ?? 'Issue Details')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', issue['status'] ?? 'Open',
                  _getStatusColor(issue['status'] ?? 'Open')),
              _buildDetailRow('Priority', issue['priority'] ?? 'Medium',
                  _getPriorityColor(issue['priority'] ?? 'Medium')),
              _buildDetailRow('Reported By', issue['reportedBy'] ?? 'Unknown',
                  Colors.white70),
              if (issue['assignedTo'] != null &&
                  (issue['assignedTo'] as String).isNotEmpty)
                _buildDetailRow(
                    'Assigned To', issue['assignedTo'], Colors.white70),
              _buildDetailRow('Created', _formatTimestamp(issue['timestamp']),
                  Colors.white70),
              if (issue['updatedAt'] != null)
                _buildDetailRow('Updated', _formatTimestamp(issue['updatedAt']),
                    Colors.white70),

              // Resolution Details
              if (issue['status'] == 'Resolved' ||
                  issue['status'] == 'Closed') ...[
                const Divider(color: Colors.white12, height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06D6A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF06D6A0).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF06D6A0), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Resolution Details',
                            style: TextStyle(
                              color: Color(0xFF06D6A0),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                          'Resolved By',
                          issue['resolvedBy'] ?? 'Unknown',
                          const Color(0xFF06D6A0)),
                      _buildDetailRow(
                          'Resolved At',
                          _formatTimestamp(issue['resolvedAt']),
                          Colors.white70),
                      if (issue['resolutionType'] != null)
                        _buildDetailRow(
                            'Type', issue['resolutionType'], Colors.white70),
                      const SizedBox(height: 8),
                      const Text(
                        'Action Taken:',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue['resolutionAction'] ?? 'No details provided',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (issue['resolutionNextSteps'] != null &&
                          (issue['resolutionNextSteps'] as String)
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Next Steps:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issue['resolutionNextSteps'],
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const Divider(color: Colors.white12, height: 24),
              const Text('Description:',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(issue['description'] ?? 'No description',
                  style: const TextStyle(color: Colors.white)),
              if (issue['photoUrl'] != null &&
                  (issue['photoUrl'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    issue['photoUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: Colors.grey[800],
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditDialog(context, issue);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(color: Colors.white38, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(Map issue) {
    final actionCtrl = TextEditingController();
    final nextStepsCtrl = TextEditingController();
    String resolutionType = 'Fixed';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F1419),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF06D6A0)),
              const SizedBox(width: 12),
              const Text('Resolve Issue'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue['title'] ?? 'Issue',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Priority: ${issue['priority']} • Category: ${issue['category']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Resolution Type
                const Text(
                  'Resolution Type',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Fixed',
                      label: Text('Fixed'),
                      icon: Icon(Icons.build),
                    ),
                    ButtonSegment(
                      value: 'Workaround',
                      label: Text('Workaround'),
                      icon: Icon(Icons.settings_suggest),
                    ),
                    ButtonSegment(
                      value: 'No Action',
                      label: Text('No Action'),
                      icon: Icon(Icons.block),
                    ),
                  ],
                  selected: {resolutionType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      resolutionType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Action Taken
                TextField(
                  controller: actionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Action Taken *',
                    hintText: 'What did you do to resolve this?',
                    helperText: 'Describe the solution or fix applied',
                    prefixIcon: const Icon(Icons.construction),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Next Steps
                TextField(
                  controller: nextStepsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Next Steps / Follow-up',
                    hintText: 'Any monitoring or future actions needed?',
                    helperText: 'Optional: What should be watched or done next',
                    prefixIcon: const Icon(Icons.arrow_forward),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),

                // Info box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will mark the issue as Resolved and record your name',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (actionCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please describe the action taken')),
                  );
                  return;
                }

                final issuesBox = Hive.box('issuesBox');
                final issueId = issue['id'] as String;
                final updated = Map<String, dynamic>.from(issue);

                updated['status'] = 'Resolved';
                updated['resolvedBy'] = widget.username;
                updated['resolvedAt'] = DateTime.now().toIso8601String();
                updated['resolutionType'] = resolutionType;
                updated['resolutionAction'] = actionCtrl.text.trim();
                updated['resolutionNextSteps'] = nextStepsCtrl.text.trim();

                // Archive to resolved issues collection
                await SyncService.archiveResolvedIssue(issueId, updated);

                // Remove from active issues
                await issuesBox.delete(issueId);
                await SyncService.deleteIssue(issueId);

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Issue resolved by ${widget.username}'),
                      backgroundColor: const Color(0xFF06D6A0),
                    ),
                  );
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Resolved'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, Map issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1419),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAddEditDialog(context, issue);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0F1419),
                    title: const Text('Delete Issue?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final issuesBox = Hive.box('issuesBox');
                  await issuesBox.delete(issue['id']);
                  await SyncService.deleteRemote('issuesBox', issue['id']);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue deleted')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
