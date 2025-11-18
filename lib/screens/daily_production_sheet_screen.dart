import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DailyProductionSheetScreen extends StatefulWidget {
  final String username;
  final int level;

  const DailyProductionSheetScreen({
    super.key,
    required this.username,
    required this.level,
  });

  @override
  State<DailyProductionSheetScreen> createState() =>
      _DailyProductionSheetScreenState();
}

class _DailyProductionSheetScreenState
    extends State<DailyProductionSheetScreen> {
  final uuid = const Uuid();
  String selectedFloor = '16A';
  DateTime selectedDate = DateTime.now();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Production Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _isExporting ? null : _exportToPDF,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Manual Entry',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Floor and Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.05),
            child: Row(
              children: [
                // Floor selector
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFloor,
                    decoration: const InputDecoration(
                      labelText: 'Floor',
                      border: OutlineInputBorder(),
                    ),
                    items: _getFloors().map((floor) {
                      return DropdownMenuItem(
                        value: floor,
                        child: Text(floor),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedFloor = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Date selector
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    onPressed: _selectDate,
                  ),
                ),
              ],
            ),
          ),

          // Production data table
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('dailyProductionBox').listenable(),
              builder: (context, box, _) {
                final entries = _getFilteredEntries(box);

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No production data for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan a jobcard or add manual entry',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.1),
                      ),
                      columns: const [
                        DataColumn(label: Text('Machine')),
                        DataColumn(label: Text('Job')),
                        DataColumn(label: Text('Works Order')),
                        DataColumn(label: Text('Day Actual')),
                        DataColumn(label: Text('Day Scrap')),
                        DataColumn(label: Text('Day Scrap %')),
                        DataColumn(label: Text('Night Actual')),
                        DataColumn(label: Text('Night Scrap')),
                        DataColumn(label: Text('Night Scrap %')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: entries.map((entry) {
                        return DataRow(
                          cells: [
                            DataCell(Text(_getMachineName(entry['machineId']))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    entry['jobName'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    entry['color'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(entry['worksOrderNo'] ?? '')),
                            DataCell(Text('${entry['dayActual'] ?? 0}')),
                            DataCell(Text('${entry['dayScrap'] ?? 0}')),
                            DataCell(
                              Text(
                                '${(entry['dayScrapRate'] ?? 0.0).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: (entry['dayScrapRate'] ?? 0.0) > 5
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text('${entry['nightActual'] ?? 0}')),
                            DataCell(Text('${entry['nightScrap'] ?? 0}')),
                            DataCell(
                              Text(
                                '${(entry['nightScrapRate'] ?? 0.0).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: (entry['nightScrapRate'] ?? 0.0) > 5
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editEntry(entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteEntry(entry['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getFloors() {
    final floorsBox = Hive.box('floorsBox');
    final floors = floorsBox.values.map((f) => f['name'] as String).toList();
    if (floors.isEmpty) {
      return ['16A', '16B']; // Default floors
    }
    return floors;
  }

  List<Map> _getFilteredEntries(Box box) {
    final dateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return box.values
        .where((entry) {
          final entryDate = entry['date'] as String?;
          final machineId = entry['machineId'] as String?;

          if (entryDate != dateStr) return false;

          // Filter by floor
          final machine = _getMachine(machineId);
          if (machine == null) return false;

          return machine['floor'] == selectedFloor;
        })
        .cast<Map>()
        .toList();
  }

  Map? _getMachine(String? machineId) {
    if (machineId == null) return null;
    final machinesBox = Hive.box('machinesBox');
    return machinesBox.get(machineId);
  }

  String _getMachineName(String? machineId) {
    final machine = _getMachine(machineId);
    return machine?['name'] ?? 'Unknown';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _showManualEntryDialog() async {
    // TODO: Implement manual entry dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual entry feature coming soon')),
    );
  }

  Future<void> _editEntry(Map entry) async {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon')),
    );
  }

  Future<void> _deleteEntry(String? id) async {
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
            'Are you sure you want to delete this production entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Hive.box('dailyProductionBox').delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final entries = _getFilteredEntries(Hive.box('dailyProductionBox'));

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Daily Production Sheet - Floor $selectedFloor',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'Machine',
                    'Job',
                    'Works Order',
                    'Day Actual',
                    'Day Scrap',
                    'Day Scrap %',
                    'Night Actual',
                    'Night Scrap',
                    'Night Scrap %',
                  ],
                  data: entries.map((entry) {
                    return [
                      _getMachineName(entry['machineId']),
                      '${entry['jobName'] ?? ''}\n${entry['color'] ?? ''}',
                      entry['worksOrderNo'] ?? '',
                      '${entry['dayActual'] ?? 0}',
                      '${entry['dayScrap'] ?? 0}',
                      '${(entry['dayScrapRate'] ?? 0.0).toStringAsFixed(1)}%',
                      '${entry['nightActual'] ?? 0}',
                      '${entry['nightScrap'] ?? 0}',
                      '${(entry['nightScrapRate'] ?? 0.0).toStringAsFixed(1)}%',
                    ];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      // Save and share PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
