// lib/screens/paperwork_screen.dart
// v7.2 – Paperwork and daily checklists for managers/setters

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class PaperworkScreen extends StatefulWidget {
  final int level;
  final String username;
  const PaperworkScreen(
      {super.key, required this.level, required this.username});

  @override
  State<PaperworkScreen> createState() => _PaperworkScreenState();
}

class _PaperworkScreenState extends State<PaperworkScreen> {
  final uuid = const Uuid();
  String selectedCategory = 'Daily Checklists';
  String? selectedSetter;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeChecklistBox();
  }

  Future<void> _initializeChecklistBox() async {
    if (!Hive.isBoxOpen('checklistsBox')) {
      await Hive.openBox('checklistsBox');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersBox = Hive.box('usersBox');
    final setters = usersBox.values
        .cast<Map>()
        .where((u) => (u['level'] as int? ?? 0) >= 2)
        .toList();

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
              title: const Text('Paperwork & Checklists'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9D4EDD).withOpacity(0.3),
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
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Category Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${DateFormat('EEEE, MMM d, yyyy').format(selectedDate)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Daily Checklists',
                            label: Text('Daily Checklists'),
                            icon: Icon(Icons.checklist),
                          ),
                          ButtonSegment(
                            value: 'By Setter',
                            label: Text('By Setter'),
                            icon: Icon(Icons.person),
                          ),
                        ],
                        selected: {selectedCategory},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            selectedCategory = newSelection.first;
                            if (selectedCategory == 'By Setter' &&
                                setters.isNotEmpty) {
                              selectedSetter ??=
                                  setters.first['username'] as String;
                            }
                          });
                        },
                      ),
                      if (selectedCategory == 'By Setter' &&
                          setters.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedSetter ??
                              setters.first['username'] as String,
                          items: setters
                              .map((s) => DropdownMenuItem(
                                  value: s['username'] as String,
                                  child: Text(s['username'] as String)))
                              .toList(),
                          onChanged: (v) => setState(() => selectedSetter = v),
                          decoration: InputDecoration(
                            labelText: 'Select Setter',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          selectedCategory == 'Daily Checklists'
              ? _buildDailyChecklists()
              : _buildSetterChecklists(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChecklistItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: const Color(0xFF4CC9F0),
      ),
    );
  }

  Widget _buildDailyChecklists() {
    return FutureBuilder(
      future: _ensureBoxOpen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }

        final checklistsBox = Hive.box('checklistsBox');
        final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
        final items = checklistsBox.values
            .cast<Map>()
            .where((item) =>
                item['date'] == dateKey &&
                (item['setter'] == null || item['setter'] == ''))
            .toList();

        if (items.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist,
                      size: 64, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No checklist items for today',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add items',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildChecklistCard(items[i]),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetterChecklists() {
    if (selectedSetter == null) {
      return const SliverFillRemaining(
          child: Center(child: Text('No setters available')));
    }

    return FutureBuilder(
      future: _ensureBoxOpen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }

        final checklistsBox = Hive.box('checklistsBox');
        final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
        final items = checklistsBox.values
            .cast<Map>()
            .where((item) =>
                item['date'] == dateKey && item['setter'] == selectedSetter)
            .toList();

        if (items.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 64, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No items for $selectedSetter today',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add items',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildChecklistCard(items[i]),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistCard(Map item) {
    final isCompleted = item['completed'] == true;
    final priority = item['priority'] as String? ?? 'Normal';
    final priorityColor = _getPriorityColor(priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : priorityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) => _toggleComplete(item, value ?? false),
          activeColor: const Color(0xFF00D26A),
        ),
        title: Text(
          item['title'] ?? 'Untitled',
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['description'] != null && item['description'] != '')
              Text(item['description'] as String),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item['setter'] != null && item['setter'] != '') ...[
                  const SizedBox(width: 8),
                  Icon(Icons.person,
                      size: 14, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    item['setter'] as String,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editChecklistItem(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteChecklistItem(item),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ensureBoxOpen() async {
    if (!Hive.isBoxOpen('checklistsBox')) {
      await Hive.openBox('checklistsBox');
    }
  }

  Future<void> _toggleComplete(Map item, bool completed) async {
    final checklistsBox = Hive.box('checklistsBox');
    final id = item['id'] as String;
    final updatedItem = Map<String, dynamic>.from(item);
    updatedItem['completed'] = completed;
    updatedItem['completedAt'] =
        completed ? DateTime.now().toIso8601String() : null;
    updatedItem['completedBy'] = completed ? widget.username : null;
    await checklistsBox.put(id, updatedItem);
    await SyncService.push('checklistsBox', id, updatedItem);
    setState(() {});
  }

  Future<void> _addChecklistItem() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Normal';
    String? setter = selectedCategory == 'By Setter' ? selectedSetter : null;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Checklist Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Normal', 'High', 'Urgent']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => priority = v ?? 'Normal'),
                ),
                if (selectedCategory == 'Daily Checklists') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: setter,
                    decoration: const InputDecoration(
                        labelText: 'Assign to Setter (optional)'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('None (General)')),
                      ...Hive.box('usersBox')
                          .values
                          .cast<Map>()
                          .where((u) => (u['level'] as int? ?? 0) >= 2)
                          .map((s) => DropdownMenuItem(
                              value: s['username'] as String,
                              child: Text(s['username'] as String))),
                    ],
                    onChanged: (v) => setDialogState(() => setter = v),
                  ),
                ],
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
                if (titleCtrl.text.trim().isEmpty) return;

                final checklistsBox = Hive.box('checklistsBox');
                final id = uuid.v4();
                final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
                final data = {
                  'id': id,
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'priority': priority,
                  'setter': setter ?? '',
                  'date': dateKey,
                  'completed': false,
                  'createdBy': widget.username,
                  'createdAt': DateTime.now().toIso8601String(),
                };
                await checklistsBox.put(id, data);
                await SyncService.push('checklistsBox', id, data);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
                setState(() {});
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editChecklistItem(Map item) async {
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final descCtrl = TextEditingController(text: item['description'] ?? '');
    String priority = item['priority'] ?? 'Normal';
    String? setter = item['setter'] ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Checklist Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Normal', 'High', 'Urgent']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => priority = v ?? 'Normal'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: setter == '' ? null : setter,
                  decoration: const InputDecoration(
                      labelText: 'Assign to Setter (optional)'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('None (General)')),
                    ...Hive.box('usersBox')
                        .values
                        .cast<Map>()
                        .where((u) => (u['level'] as int? ?? 0) >= 2)
                        .map((s) => DropdownMenuItem(
                            value: s['username'] as String,
                            child: Text(s['username'] as String))),
                  ],
                  onChanged: (v) => setDialogState(() => setter = v),
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
                if (titleCtrl.text.trim().isEmpty) return;

                final checklistsBox = Hive.box('checklistsBox');
                final id = item['id'] as String;
                final updatedItem = Map<String, dynamic>.from(item);
                updatedItem['title'] = titleCtrl.text.trim();
                updatedItem['description'] = descCtrl.text.trim();
                updatedItem['priority'] = priority;
                updatedItem['setter'] = setter ?? '';
                await checklistsBox.put(id, updatedItem);
                await SyncService.push('checklistsBox', id, updatedItem);
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

  Future<void> _deleteChecklistItem(Map item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content:
            const Text('Are you sure you want to delete this checklist item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final checklistsBox = Hive.box('checklistsBox');
      final id = item['id'] as String;
      await checklistsBox.delete(id);
      await SyncService.deleteRemote('checklistsBox', id);
      setState(() {});
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return const Color(0xFF4CC9F0);
      case 'Normal':
        return const Color(0xFF80ED99);
      case 'High':
        return const Color(0xFFFFD166);
      case 'Urgent':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF6C757D);
    }
  }
}
