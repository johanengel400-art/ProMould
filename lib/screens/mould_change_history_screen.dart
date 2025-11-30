import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class MouldChangeHistoryScreen extends StatelessWidget {
  const MouldChangeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Mould Change History'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('mouldChangesBox').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'No mould changes recorded',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final changes = box.values.cast<Map>().toList()
            ..sort((a, b) => (b['completedAt'] as String)
                .compareTo(a['completedAt'] as String));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: changes.length,
            itemBuilder: (context, index) {
              final change = changes[index];
              return _buildChangeCard(context, change);
            },
          );
        },
      ),
    );
  }

  Widget _buildChangeCard(BuildContext context, Map change) {
    final date = DateTime.parse(change['date'] as String);
    final completedAt = DateTime.parse(change['completedAt'] as String);
    
    final removalChecks = Map<String, bool>.from(change['removalChecks'] as Map);
    final installChecks = Map<String, bool>.from(change['installationChecks'] as Map);
    
    final removalComplete = removalChecks.values.where((v) => v).length;
    final installComplete = installChecks.values.where((v) => v).length;
    final totalRemoval = removalChecks.length;
    final totalInstall = installChecks.length;

    return Card(
      color: const Color(0xFF1A1F2E),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetails(context, change),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Machine: ${change['machineId']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (change['mouldRemoved'] != null && (change['mouldRemoved'] as String).isNotEmpty)
                Text(
                  'Removed: ${change['mouldRemoved']}',
                  style: const TextStyle(color: Colors.red),
                ),
              Text(
                'Installed: ${change['mouldInstalled']}',
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'Setter: ${change['setterName']}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Removal',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: removalComplete / totalRemoval,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$removalComplete/$totalRemoval',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Installation',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: installComplete / totalInstall,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$installComplete/$totalInstall',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map change) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Mould Change Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailSection('General Information', [
                'Machine ID: ${change['machineId']}',
                'Mould Removed: ${change['mouldRemoved'] ?? 'N/A'}',
                'Mould Installed: ${change['mouldInstalled']}',
                'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(change['date']))}',
                'Start Time: ${change['startTime']}',
                'Setter: ${change['setterName']}',
                'Assistants: ${change['assistantNames'] ?? 'N/A'}',
              ]),
              const SizedBox(height: 16),
              _buildChecklistDetails(
                'Removal Checklist',
                Map<String, bool>.from(change['removalChecks'] as Map),
                Map<String, String>.from(change['removalComments'] as Map),
              ),
              const SizedBox(height: 16),
              _buildChecklistDetails(
                'Installation Checklist',
                Map<String, bool>.from(change['installationChecks'] as Map),
                Map<String, String>.from(change['installationComments'] as Map),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: const TextStyle(color: Colors.white70),
              ),
            )),
      ],
    );
  }

  Widget _buildChecklistDetails(
    String title,
    Map<String, bool> checks,
    Map<String, String> comments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...checks.entries.map((entry) {
          final checked = entry.value;
          final comment = comments[entry.key] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  checked ? Icons.check_circle : Icons.cancel,
                  color: checked ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (comment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Comment: $comment',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
