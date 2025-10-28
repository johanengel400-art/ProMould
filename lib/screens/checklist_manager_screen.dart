import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/checklist_export_service.dart';

class ChecklistManagerScreen extends StatefulWidget {
  const ChecklistManagerScreen({super.key});

  @override
  State<ChecklistManagerScreen> createState() => _ChecklistManagerScreenState();
}

class _ChecklistManagerScreenState extends State<ChecklistManagerScreen> {
  final _uuid = const Uuid();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    if (!Hive.isBoxOpen('checklistsBox')) {
      await Hive.openBox('checklistsBox');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Checklist Manager'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
            tooltip: 'Export All',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateChecklistDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('checklistsBox').listenable(),
              builder: (context, box, _) {
                final checklists = box.values.cast<Map>().map((c) => Map<String, dynamic>.from(c)).where((c) {
                  if (_selectedCategory == 'All') return true;
                  return c['category'] == _selectedCategory;
                }).toList();

                if (checklists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        const Text(
                          'No checklists found',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to create your first checklist',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: checklists.length,
                  itemBuilder: (context, index) {
                    final checklist = checklists[index];
                    return _buildChecklistCard(checklist);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip('All'),
            _buildCategoryChip('Safety'),
            _buildCategoryChip('Quality'),
            _buildCategoryChip('Maintenance'),
            _buildCategoryChip('Production'),
            _buildCategoryChip('Setup'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
        backgroundColor: const Color(0xFF2D2D2D),
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    final items = checklist['items'] as List? ?? [];
    final completedCount = items.where((i) => i['isCompleted'] == true).length;
    final totalCount = items.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount * 100).toDouble() : 0.0;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showChecklistDetails(checklist),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checklist['category'] ?? 'Uncategorized',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: const Color(0xFF2D2D2D),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export_pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Export as PDF', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_csv',
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Export as CSV', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Duplicate', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleMenuAction(value.toString(), checklist),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount / $totalCount items',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (completionRate / 100).toDouble(),
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(completionRate),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${completionRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _getProgressColor(completionRate),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Color _getProgressColor(double rate) {
    if (rate >= 100) return Colors.green;
    if (rate >= 75) return Colors.blue;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  void _handleMenuAction(String action, Map<String, dynamic> checklist) async {
    switch (action) {
      case 'export_pdf':
        await _exportChecklistPDF(checklist);
        break;
      case 'export_csv':
        await _exportChecklistCSV(checklist);
        break;
      case 'duplicate':
        await _duplicateChecklist(checklist);
        break;
      case 'delete':
        _confirmDelete(checklist);
        break;
    }
  }

  Future<void> _exportChecklistPDF(Map<String, dynamic> checklist) async {
    try {
      await ChecklistExportService.exportToPDF(checklist);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist exported as PDF')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportChecklistCSV(Map<String, dynamic> checklist) async {
    try {
      await ChecklistExportService.exportToCSV(checklist);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist exported as CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _duplicateChecklist(Map<String, dynamic> checklist) async {
    final box = Hive.box('checklistsBox');
    final newId = _uuid.v4();
    final duplicate = Map<String, dynamic>.from(checklist);
    duplicate['id'] = newId;
    duplicate['title'] = '${checklist['title']} (Copy)';
    duplicate['createdAt'] = DateTime.now().toIso8601String();
    
    // Reset completion status
    final items = (duplicate['items'] as List).map((item) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['isCompleted'] = false;
      newItem['notes'] = '';
      return newItem;
    }).toList();
    duplicate['items'] = items;

    await box.put(newId, duplicate);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist duplicated')),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Checklist', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${checklist['title']}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Hive.box('checklistsBox').delete(checklist['id']);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showChecklistDetails(Map<String, dynamic> checklist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistDetailScreen(checklist: checklist),
      ),
    );
  }

  void _showCreateChecklistDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateChecklistDialog(),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Export All Checklists', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Choose export format:',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportAllCSV();
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllCSV() async {
    try {
      final box = Hive.box('checklistsBox');
      final checklists = box.values.cast<Map>().map((c) => Map<String, dynamic>.from(c)).toList();
      await ChecklistExportService.exportMultipleToCSV(checklists);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All checklists exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _CreateChecklistDialog extends StatefulWidget {
  const _CreateChecklistDialog();

  @override
  State<_CreateChecklistDialog> createState() => _CreateChecklistDialogState();
}

class _CreateChecklistDialogState extends State<_CreateChecklistDialog> {
  final _titleController = TextEditingController();
  String _category = 'Safety';
  final _items = <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Create Checklist', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: const Color(0xFF2D2D2D),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'Safety', child: Text('Safety')),
                DropdownMenuItem(value: 'Quality', child: Text('Quality')),
                DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                DropdownMenuItem(value: 'Production', child: Text('Production')),
                DropdownMenuItem(value: 'Setup', child: Text('Setup')),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(color: Colors.white)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                title: Text(item['title'], style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _items.removeAt(index)),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Item', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Item Title',
              labelStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _items.add({
                      'title': controller.text,
                      'isCompleted': false,
                      'notes': '',
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _save() async {
    if (_titleController.text.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add at least one item')),
      );
      return;
    }

    final box = Hive.box('checklistsBox');
    final id = const Uuid().v4();
    
    await box.put(id, {
      'id': id,
      'title': _titleController.text,
      'category': _category,
      'items': _items,
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}

class ChecklistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> checklist;

  const ChecklistDetailScreen({super.key, required this.checklist});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = (widget.checklist['items'] as List)
        .map((i) => Map<String, dynamic>.from(i))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _items.where((i) => i['isCompleted'] == true).length;
    final totalCount = _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.checklist['title']),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: $completedCount / $totalCount',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '${(completedCount / totalCount * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completedCount / totalCount,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildChecklistItem(item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, int index) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item['isCompleted'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      item['isCompleted'] = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                Expanded(
                  child: Text(
                    item['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: (item['isCompleted'] ?? false)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if (item['notes'] != null && (item['notes'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['notes'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: TextButton.icon(
                onPressed: () => _addNotes(item),
                icon: const Icon(Icons.note_add, size: 16),
                label: Text(
                  (item['notes'] == null || (item['notes'] as String).isEmpty)
                      ? 'Add Notes'
                      : 'Edit Notes',
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNotes(Map<String, dynamic> item) {
    final controller = TextEditingController(text: item['notes'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Notes', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter notes...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item['notes'] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    final box = Hive.box('checklistsBox');
    final updated = Map<String, dynamic>.from(widget.checklist);
    updated['items'] = _items;
    await box.put(widget.checklist['id'], updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved')),
      );
      Navigator.pop(context);
    }
  }
}
