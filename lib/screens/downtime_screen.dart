// lib/screens/downtime_screen.dart
// v7.2 – Downtime tracking + OEE data source + machine selection + photo upload

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';
import '../services/photo_service.dart';

class DowntimeScreen extends StatefulWidget {
  final int level;
  const DowntimeScreen({super.key, required this.level});

  @override
  State<DowntimeScreen> createState() => _DowntimeScreenState();
}

class _DowntimeScreenState extends State<DowntimeScreen> {
  final uuid = const Uuid();
  final categories = const [
    'Mechanical Failure',
    'Electrical Fault',
    'Material Shortage',
    'Mould Change',
    'Setup',
    'Quality Issue',
    'Other',
  ];

  Future<void> _addOrEdit({Map<String, dynamic>? item}) async {
    final machinesBox = Hive.box('machinesBox');
    final machines = machinesBox.values.cast<Map>().toList();
    
    final reasonCtrl = TextEditingController(text: item?['reason'] ?? '');
    final minCtrl = TextEditingController(
        text: item?['minutes'] != null ? '${item!['minutes']}' : '0');
    String category = item?['category'] ?? categories.first;
    String? machineId = item?['machineId'] ?? (machines.isNotEmpty ? machines.first['id'] as String : null);
    String? photoUrl = item?['photoUrl'];
    DateTime date = DateTime.tryParse(item?['date'] ?? '') ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Log Downtime' : 'Edit Downtime'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? categories.first),
                ),
                const SizedBox(height: 8),
                if (machines.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: machineId,
                    decoration: const InputDecoration(labelText: 'Machine'),
                    items: machines
                        .map((m) => DropdownMenuItem(
                            value: m['id'] as String, 
                            child: Text(m['name'] as String)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => machineId = v),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason / Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minCtrl,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${date.toString().substring(0, 16)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        date = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          date.hour,
                          date.minute,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_camera),
                  title: Text(photoUrl != null ? 'Photo attached' : 'Add photo (optional)'),
                  trailing: photoUrl != null 
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setDialogState(() => photoUrl = null),
                      )
                    : null,
                  onTap: () async {
                    final tempId = item?['id'] ?? uuid.v4();
                    final url = await PhotoService.uploadDowntimePhoto(tempId);
                    if (url != null) {
                      setDialogState(() => photoUrl = url);
                    }
                  },
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
                final box = Hive.box('downtimeBox');
                final id = item?['id'] ?? uuid.v4();
                final data = {
                  'id': id,
                  'category': category,
                  'machineId': machineId,
                  'reason': reasonCtrl.text.trim(),
                  'minutes': int.tryParse(minCtrl.text) ?? 0,
                  'date': date.toIso8601String(),
                  if (photoUrl != null) 'photoUrl': photoUrl,
                };
                await box.put(id, data);
                await SyncService.push('downtimeBox', id, data);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
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

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('downtimeBox');
    final machinesBox = Hive.box('machinesBox');
    final items = box.values.cast<Map>().toList().reversed.toList();

    // Calculate total downtime
    final totalMinutes = items.fold<int>(0, (sum, item) => sum + (item['minutes'] as int? ?? 0));
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

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
              title: const Text('Downtime Tracking'),
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
            actions: [
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF476F).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF476F).withOpacity(0.5)),
                      ),
                      child: Text(
                        'Total: ${hours}h ${minutes}m',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF476F)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          items.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.access_time, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No downtime recorded', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final d = items[i];
                        final categoryColor = _getCategoryColor(d['category'] ?? '');
                        final machineId = d['machineId'] as String?;
                        final machine = machineId != null 
                            ? machinesBox.get(machineId) as Map?
                            : null;
                        final machineName = machine?['name'] ?? 'No machine';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF0F1419),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(d['category'] ?? ''),
                                color: categoryColor,
                              ),
                            ),
                            title: Text(
                              '$machineName • ${d['category']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  '${d['reason'] ?? 'No description'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 14, color: categoryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${d['minutes']} min',
                                      style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time, size: 14, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(d['date']),
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (d['photoUrl'] != null) ...[
                                  const SizedBox(height: 4),
                                  const Row(
                                    children: [
                                      Icon(Icons.photo, size: 14, color: Colors.white54),
                                      SizedBox(width: 4),
                                      Text('Photo attached', style: TextStyle(fontSize: 12, color: Colors.white54)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white38),
                              itemBuilder: (context) => [
                                if (d['photoUrl'] != null)
                                  const PopupMenuItem(
                                    value: 'photo',
                                    child: Row(
                                      children: [
                                        Icon(Icons.photo_outlined),
                                        SizedBox(width: 8),
                                        Text('View Photo'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'photo' && d['photoUrl'] != null) {
                                  _showPhoto(d['photoUrl'] as String);
                                } else if (value == 'edit') {
                                  _addOrEdit(item: Map<String, dynamic>.from(d));
                                } else if (value == 'delete') {
                                  final downtimeId = d['id'] as String;
                                  await box.delete(downtimeId);
                                  await SyncService.deleteRemote('downtimeBox', downtimeId);
                                  setState(() {});
                                }
                              },
                            ),
                            onTap: () => _addOrEdit(item: Map<String, dynamic>.from(d)),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: const Color(0xFFEF476F),
        icon: const Icon(Icons.add),
        label: const Text('Log Downtime'),
      ),
    );
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Mechanical Failure':
        return const Color(0xFFFF6B6B);
      case 'Electrical Fault':
        return const Color(0xFFFFD166);
      case 'Material Shortage':
        return const Color(0xFF4CC9F0);
      case 'Mould Change':
        return const Color(0xFF80ED99);
      case 'Setup':
        return const Color(0xFF9D4EDD);
      case 'Quality Issue':
        return const Color(0xFFF72585);
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Mechanical Failure':
        return Icons.build_outlined;
      case 'Electrical Fault':
        return Icons.electrical_services_outlined;
      case 'Material Shortage':
        return Icons.inventory_2_outlined;
      case 'Mould Change':
        return Icons.swap_horiz;
      case 'Setup':
        return Icons.settings_outlined;
      case 'Quality Issue':
        return Icons.warning_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }
}
