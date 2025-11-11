import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportBuilderScreen extends StatefulWidget {
  const ReportBuilderScreen({super.key});

  @override
  State<ReportBuilderScreen> createState() => _ReportBuilderScreenState();
}

class _ReportBuilderScreenState extends State<ReportBuilderScreen> {
  String _reportType = 'production';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? _selectedMachine;
  String? _selectedOperator;
  bool _includeCharts = true;
  bool _includeSummary = true;
  bool _includeDetails = true;

  List<Map<String, dynamic>> _reportData = [];
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Custom Report Builder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildReportTypeSelector(),
                const SizedBox(height: 16),
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 16),
                _buildOptions(),
                const SizedBox(height: 24),
                if (_reportData.isNotEmpty) _buildPreview(),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip('Production', 'production', Icons.factory),
                _buildTypeChip('Quality', 'quality', Icons.verified),
                _buildTypeChip('Downtime', 'downtime', Icons.warning),
                _buildTypeChip('Machine Performance', 'machine',
                    Icons.precision_manufacturing),
                _buildTypeChip(
                    'Operator Performance', 'operator', Icons.person),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _reportType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _reportType = value);
      },
      backgroundColor: const Color(0xFF2D2D2D),
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    'Start Date',
                    _startDate,
                    (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    'End Date',
                    _endDate,
                    (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickDateChip('Last 7 Days', 7),
                _buildQuickDateChip('Last 30 Days', 30),
                _buildQuickDateChip('Last 90 Days', 90),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
      String label, DateTime date, Function(DateTime) onSelect) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onSelect(picked);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(Duration(days: days));
        });
      },
      backgroundColor: const Color(0xFF2D2D2D),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildFilters() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_reportType == 'production' ||
                _reportType == 'machine' ||
                _reportType == 'downtime')
              _buildMachineFilter(),
            if (_reportType == 'production' || _reportType == 'operator')
              _buildOperatorFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineFilter() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('machinesBox').listenable(),
      builder: (context, box, _) {
        final machines = box.values.cast<Map>().toList();
        return DropdownButtonFormField<String>(
          value: _selectedMachine,
          decoration: const InputDecoration(
            labelText: 'Machine (Optional)',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          dropdownColor: const Color(0xFF2D2D2D),
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All Machines'),
            ),
            ...machines.map((m) => DropdownMenuItem(
                  value: m['id'],
                  child: Text(m['name']),
                )),
          ],
          onChanged: (value) => setState(() => _selectedMachine = value),
        );
      },
    );
  }

  Widget _buildOperatorFilter() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('operatorsBox').listenable(),
      builder: (context, box, _) {
        final operators = box.values.cast<Map>().toList();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            value: _selectedOperator,
            decoration: const InputDecoration(
              labelText: 'Operator (Optional)',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
            ),
            dropdownColor: const Color(0xFF2D2D2D),
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Operators'),
              ),
              ...operators.map((o) => DropdownMenuItem(
                    value: o['id'],
                    child: Text(o['name']),
                  )),
            ],
            onChanged: (value) => setState(() => _selectedOperator = value),
          ),
        );
      },
    );
  }

  Widget _buildOptions() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            CheckboxListTile(
              title: const Text('Include Summary',
                  style: TextStyle(color: Colors.white)),
              value: _includeSummary,
              onChanged: (value) =>
                  setState(() => _includeSummary = value ?? true),
              activeColor: Colors.blue,
            ),
            CheckboxListTile(
              title: const Text('Include Charts',
                  style: TextStyle(color: Colors.white)),
              value: _includeCharts,
              onChanged: (value) =>
                  setState(() => _includeCharts = value ?? true),
              activeColor: Colors.blue,
            ),
            CheckboxListTile(
              title: const Text('Include Detailed Data',
                  style: TextStyle(color: Colors.white)),
              value: _includeDetails,
              onChanged: (value) =>
                  setState(() => _includeDetails = value ?? true),
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Preview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_reportData.length} records found',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _reportData.take(5).length,
                itemBuilder: (context, index) {
                  final item = _reportData[index];
                  return ListTile(
                    title: Text(
                      item['title'] ?? 'Item ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      item['subtitle'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: const Icon(Icons.preview),
              label: const Text('Generate Preview'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _reportData.isEmpty || _isGenerating ? null : _exportReport,
              icon: const Icon(Icons.download),
              label: const Text('Export Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateReport() async {
    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final data = <Map<String, dynamic>>[];

    switch (_reportType) {
      case 'production':
        data.addAll(_generateProductionReport());
        break;
      case 'quality':
        data.addAll(_generateQualityReport());
        break;
      case 'downtime':
        data.addAll(_generateDowntimeReport());
        break;
      case 'machine':
        data.addAll(_generateMachineReport());
        break;
      case 'operator':
        data.addAll(_generateOperatorReport());
        break;
    }

    setState(() {
      _reportData = data;
      _isGenerating = false;
    });
  }

  List<Map<String, dynamic>> _generateProductionReport() {
    final inputsBox = Hive.box('inputsBox');
    final data = <Map<String, dynamic>>[];

    for (final input in inputsBox.values.cast<Map>()) {
      final date = DateTime.tryParse(input['date'] ?? '');
      if (date == null) continue;
      if (date.isBefore(_startDate) || date.isAfter(_endDate)) continue;
      if (_selectedMachine != null && input['machineId'] != _selectedMachine)
        continue;
      if (_selectedOperator != null && input['operatorId'] != _selectedOperator)
        continue;

      data.add({
        'title': 'Production - ${DateFormat('MMM dd').format(date)}',
        'subtitle': 'Shots: ${input['shots']}, Scrap: ${input['scrap']}',
        'data': input,
      });
    }

    return data;
  }

  List<Map<String, dynamic>> _generateQualityReport() {
    final issuesBox = Hive.box('issuesBox');
    final data = <Map<String, dynamic>>[];

    for (final issue in issuesBox.values.cast<Map>()) {
      final timestamp = DateTime.tryParse(issue['timestamp'] ?? '');
      if (timestamp == null) continue;
      if (timestamp.isBefore(_startDate) || timestamp.isAfter(_endDate))
        continue;
      if (_selectedMachine != null && issue['machineId'] != _selectedMachine)
        continue;

      data.add({
        'title': issue['title'] ?? 'Issue',
        'subtitle':
            'Priority: ${issue['priority']}, Status: ${issue['status']}',
        'data': issue,
      });
    }

    return data;
  }

  List<Map<String, dynamic>> _generateDowntimeReport() {
    final downtimeBox = Hive.box('downtimeBox');
    final data = <Map<String, dynamic>>[];

    for (final downtime in downtimeBox.values.cast<Map>()) {
      final date = DateTime.tryParse(downtime['date'] ?? '');
      if (date == null) continue;
      if (date.isBefore(_startDate) || date.isAfter(_endDate)) continue;
      if (_selectedMachine != null && downtime['machineId'] != _selectedMachine)
        continue;

      data.add({
        'title': 'Downtime - ${downtime['reason']}',
        'subtitle': '${downtime['minutes']} minutes',
        'data': downtime,
      });
    }

    return data;
  }

  List<Map<String, dynamic>> _generateMachineReport() {
    final jobsBox = Hive.box('jobsBox');
    final machineStats = <String, Map<String, dynamic>>{};

    for (final job in jobsBox.values.cast<Map>()) {
      final startTime = DateTime.tryParse(job['startTime'] ?? '');
      if (startTime == null) continue;
      if (startTime.isBefore(_startDate) || startTime.isAfter(_endDate))
        continue;
      if (_selectedMachine != null && job['machineId'] != _selectedMachine)
        continue;

      final machineId = job['machineId'] as String;
      if (!machineStats.containsKey(machineId)) {
        machineStats[machineId] = {
          'machineId': machineId,
          'machineName': job['machineName'] ?? 'Unknown',
          'totalJobs': 0,
          'completedJobs': 0,
        };
      }

      machineStats[machineId]!['totalJobs']++;
      if (job['status'] == 'Finished') {
        machineStats[machineId]!['completedJobs']++;
      }
    }

    return machineStats.values
        .map((stats) => {
              'title': stats['machineName'],
              'subtitle':
                  'Jobs: ${stats['totalJobs']}, Completed: ${stats['completedJobs']}',
              'data': stats,
            })
        .toList();
  }

  List<Map<String, dynamic>> _generateOperatorReport() {
    final inputsBox = Hive.box('inputsBox');
    final operatorStats = <String, Map<String, dynamic>>{};

    for (final input in inputsBox.values.cast<Map>()) {
      final date = DateTime.tryParse(input['date'] ?? '');
      if (date == null) continue;
      if (date.isBefore(_startDate) || date.isAfter(_endDate)) continue;
      if (_selectedOperator != null && input['operatorId'] != _selectedOperator)
        continue;

      final operatorId = input['operatorId'] as String?;
      if (operatorId == null) continue;

      if (!operatorStats.containsKey(operatorId)) {
        operatorStats[operatorId] = {
          'operatorId': operatorId,
          'operatorName': input['operatorName'] ?? 'Unknown',
          'totalShots': 0,
          'totalScrap': 0,
        };
      }

      operatorStats[operatorId]!['totalShots'] += input['shots'] as int? ?? 0;
      operatorStats[operatorId]!['totalScrap'] += input['scrap'] as int? ?? 0;
    }

    return operatorStats.values
        .map((stats) => {
              'title': stats['operatorName'],
              'subtitle':
                  'Shots: ${stats['totalShots']}, Scrap: ${stats['totalScrap']}',
              'data': stats,
            })
        .toList();
  }

  void _exportReport() async {
    try {
      final csv = _generateCSV();
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'report_${_reportType}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ProMould Report - $_reportType',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully')),
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

  String _generateCSV() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('ProMould Report - $_reportType');
    buffer.writeln(
        'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln(
        'Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}');
    buffer.writeln('');

    // Data headers
    switch (_reportType) {
      case 'production':
        buffer.writeln('Date,Machine,Operator,Shots,Scrap,Scrap Rate');
        for (final item in _reportData) {
          final data = item['data'] as Map;
          final date = DateTime.parse(data['date']);
          final shots = data['shots'] ?? 0;
          final scrap = data['scrap'] ?? 0;
          final scrapRate = (shots + scrap) > 0
              ? (scrap / (shots + scrap) * 100).toStringAsFixed(2)
              : '0';
          buffer.writeln(
              '${DateFormat('yyyy-MM-dd').format(date)},${data['machineName']},${data['operatorName']},$shots,$scrap,$scrapRate%');
        }
        break;
      case 'quality':
        buffer.writeln('Date,Title,Priority,Status,Category');
        for (final item in _reportData) {
          final data = item['data'] as Map;
          final timestamp = DateTime.parse(data['timestamp']);
          buffer.writeln(
              '${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)},${data['title']},${data['priority']},${data['status']},${data['category']}');
        }
        break;
      case 'downtime':
        buffer.writeln('Date,Machine,Reason,Minutes');
        for (final item in _reportData) {
          final data = item['data'] as Map;
          final date = DateTime.parse(data['date']);
          buffer.writeln(
              '${DateFormat('yyyy-MM-dd').format(date)},${data['machineName']},${data['reason']},${data['minutes']}');
        }
        break;
      case 'machine':
        buffer.writeln('Machine,Total Jobs,Completed Jobs,Completion Rate');
        for (final item in _reportData) {
          final data = item['data'] as Map;
          final completionRate = data['totalJobs'] > 0
              ? ((data['completedJobs'] / data['totalJobs']) * 100)
                  .toStringAsFixed(1)
              : '0';
          buffer.writeln(
              '${data['machineName']},${data['totalJobs']},${data['completedJobs']},$completionRate%');
        }
        break;
      case 'operator':
        buffer.writeln('Operator,Total Shots,Total Scrap,Scrap Rate');
        for (final item in _reportData) {
          final data = item['data'] as Map;
          final scrapRate = (data['totalShots'] + data['totalScrap']) > 0
              ? ((data['totalScrap'] /
                          (data['totalShots'] + data['totalScrap'])) *
                      100)
                  .toStringAsFixed(2)
              : '0';
          buffer.writeln(
              '${data['operatorName']},${data['totalShots']},${data['totalScrap']},$scrapRate%');
        }
        break;
    }

    return buffer.toString();
  }
}
