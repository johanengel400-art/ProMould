import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../utils/jobcard_models.dart';
import '../services/sync_service.dart';

class JobcardReviewScreen extends StatefulWidget {
  final JobcardData jobcardData;
  final String imagePath;
  final int level;

  const JobcardReviewScreen({
    super.key,
    required this.jobcardData,
    required this.imagePath,
    required this.level,
  });

  @override
  State<JobcardReviewScreen> createState() => _JobcardReviewScreenState();
}

class _JobcardReviewScreenState extends State<JobcardReviewScreen> {
  late TextEditingController _worksOrderCtrl;
  late TextEditingController _jobNameCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _dailyOutputCtrl;
  late TextEditingController _cycleWeightCtrl;
  late TextEditingController _targetCycleDayCtrl;
  late TextEditingController _targetCycleNightCtrl;

  final uuid = const Uuid();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _worksOrderCtrl = TextEditingController(
      text: widget.jobcardData.worksOrderNo.value ?? '',
    );
    _jobNameCtrl = TextEditingController(
      text: widget.jobcardData.jobName.value ?? '',
    );
    _colorCtrl = TextEditingController(
      text: widget.jobcardData.color.value ?? '',
    );
    _quantityCtrl = TextEditingController(
      text: widget.jobcardData.quantityToManufacture.value?.toString() ?? '',
    );
    _dailyOutputCtrl = TextEditingController(
      text: widget.jobcardData.dailyOutput.value?.toString() ?? '',
    );
    _cycleWeightCtrl = TextEditingController(
      text: widget.jobcardData.cycleWeightGrams.value?.toString() ?? '',
    );
    _targetCycleDayCtrl = TextEditingController(
      text: widget.jobcardData.targetCycleDay.value?.toString() ?? '',
    );
    _targetCycleNightCtrl = TextEditingController(
      text: widget.jobcardData.targetCycleNight.value?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _worksOrderCtrl.dispose();
    _jobNameCtrl.dispose();
    _colorCtrl.dispose();
    _quantityCtrl.dispose();
    _dailyOutputCtrl.dispose();
    _cycleWeightCtrl.dispose();
    _targetCycleDayCtrl.dispose();
    _targetCycleNightCtrl.dispose();
    super.dispose();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildConfidenceIndicator(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getConfidenceColor(confidence).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getConfidenceColor(confidence),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidence >= 0.6 ? Icons.check_circle : Icons.warning,
            size: 14,
            color: _getConfidenceColor(confidence),
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getConfidenceColor(confidence),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWithConfidence({
    required String label,
    required TextEditingController controller,
    required double confidence,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildConfidenceIndicator(confidence),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createJob() async {
    // Validate required fields
    if (_worksOrderCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Works Order No is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final jobsBox = Hive.box('jobsBox');
      final worksOrderNo = _worksOrderCtrl.text.trim();

      // Check if job already exists
      final existingJob = jobsBox.values.firstWhere(
        (job) => job['worksOrderNo'] == worksOrderNo,
        orElse: () => null,
      );

      if (existingJob != null) {
        // Job exists - add production data only
        await _addProductionData(existingJob);
      } else {
        // New job - show machine selection dialog
        await _createNewJob();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addProductionData(Map<String, dynamic> existingJob) async {
    // Verify job is on same machine
    final currentMachine = existingJob['machineId'] as String?;

    if (currentMachine == null || currentMachine.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job exists but has no machine assigned'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add production rows to Daily Production Sheet
    final dpsBox = Hive.box('dailyProductionBox');

    for (final row in widget.jobcardData.productionRows) {
      final dpsId = uuid.v4();
      final dpsEntry = {
        'id': dpsId,
        'date': row.date.value,
        'machineId': currentMachine,
        'worksOrderNo': _worksOrderCtrl.text.trim(),
        'jobName': _jobNameCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'dayActual': row.dayActual.value ?? 0,
        'dayScrap': row.dayScrap.value ?? 0,
        'dayScrapRate': row.dayScrapRate,
        'nightActual': row.nightActual.value ?? 0,
        'nightScrap': row.nightScrap.value ?? 0,
        'nightScrapRate': row.nightScrapRate,
        'dayCounterStart': row.dayCounterStart.value ?? 0,
        'dayCounterEnd': row.dayCounterEnd.value ?? 0,
        'nightCounterStart': row.nightCounterStart.value ?? 0,
        'nightCounterEnd': row.nightCounterEnd.value ?? 0,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await dpsBox.put(dpsId, dpsEntry);
      await SyncService.pushChange('dailyProductionBox', dpsId, dpsEntry);
    }

    // Update job's actual count
    final totalActual = widget.jobcardData.productionRows.fold<int>(
      0,
      (sum, row) =>
          sum + (row.dayActual.value ?? 0) + (row.nightActual.value ?? 0),
    );

    existingJob['shotsCompleted'] =
        (existingJob['shotsCompleted'] ?? 0) + totalActual;
    await Hive.box('jobsBox').put(existingJob['id'], existingJob);
    await SyncService.pushChange('jobsBox', existingJob['id'], existingJob);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Added ${widget.jobcardData.productionRows.length} production entries to existing job'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _createNewJob() async {
    // Show machine selection dialog
    final machinesBox = Hive.box('machinesBox');
    final machines = machinesBox.values.toList();

    if (machines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No machines available. Please add machines first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedMachine = await showDialog<Map>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Machine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: machines.map((machine) {
              return ListTile(
                title: Text(machine['name'] ?? 'Unknown'),
                subtitle: Text('Floor: ${machine['floor'] ?? 'Unknown'}'),
                onTap: () => Navigator.pop(context, machine),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedMachine == null) return;

    // Auto-match mould
    final mouldId = await _autoMatchMould(selectedMachine['id']);

    // Create new job
    final jobsBox = Hive.box('jobsBox');
    final id = uuid.v4();

    final jobData = {
      'id': id,
      'worksOrderNo': _worksOrderCtrl.text.trim(),
      'jobcardNumber': _worksOrderCtrl.text.trim(),
      'productName': _jobNameCtrl.text.trim(),
      'color': _colorCtrl.text.trim(),
      'targetShots': int.tryParse(_quantityCtrl.text.trim()) ?? 0,
      'shotsCompleted': 0,
      'machineId': selectedMachine['id'],
      'mouldId': mouldId,
      'status': 'Pending',
      'startTime': null,
      'endTime': null,
      'dailyOutput': int.tryParse(_dailyOutputCtrl.text.trim()),
      'cycleWeightGrams': double.tryParse(_cycleWeightCtrl.text.trim()),
      'targetCycleDay': int.tryParse(_targetCycleDayCtrl.text.trim()),
      'targetCycleNight': int.tryParse(_targetCycleNightCtrl.text.trim()),
      'jobcardImagePath': widget.imagePath,
      'jobcardScannedAt': DateTime.now().toIso8601String(),
      'jobcardConfidence': widget.jobcardData.overallConfidence,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await jobsBox.put(id, jobData);
    await SyncService.pushChange('jobsBox', id, jobData);

    // Add production data if any
    if (widget.jobcardData.productionRows.isNotEmpty) {
      await _addProductionData(jobData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<String?> _autoMatchMould(String machineId) async {
    final mouldsBox = Hive.box('mouldsBox');
    final cycleWeight = double.tryParse(_cycleWeightCtrl.text.trim());
    final jobName = _jobNameCtrl.text.trim().toLowerCase();

    if (cycleWeight == null) return null;

    // Find moulds matching cycle weight (within 10% tolerance)
    final matchingMoulds = mouldsBox.values.where((mould) {
      final mouldWeight = mould['cycleWeight'] as double?;
      if (mouldWeight == null) return false;

      final diff = (mouldWeight - cycleWeight).abs();
      final tolerance = cycleWeight * 0.1; // 10% tolerance

      return diff <= tolerance;
    }).toList();

    if (matchingMoulds.isEmpty) return null;

    // If multiple matches, try name matching
    if (matchingMoulds.length > 1) {
      for (final mould in matchingMoulds) {
        final mouldName = (mould['name'] as String?)?.toLowerCase() ?? '';
        if (mouldName.contains(jobName) || jobName.contains(mouldName)) {
          return mould['id'];
        }
      }
    }

    // Return first match
    return matchingMoulds.first['id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Jobcard Data'),
        actions: [
          // Show raw OCR text button
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'View Raw OCR Text',
            onPressed: () {
              final rawText =
                  widget.jobcardData.rawOcrText.value ?? 'No text available';
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Raw OCR Text'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      rawText,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rawText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('OCR text copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Copy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.jobcardData.hasLowConfidenceFields)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.warning_amber,
                color: Colors.orange,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Overall confidence banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getConfidenceColor(widget.jobcardData.overallConfidence)
                .withOpacity(0.2),
            child: Row(
              children: [
                Icon(
                  widget.jobcardData.overallConfidence >= 0.6
                      ? Icons.check_circle
                      : Icons.warning,
                  color:
                      _getConfidenceColor(widget.jobcardData.overallConfidence),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Confidence: ${(widget.jobcardData.overallConfidence * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.jobcardData.hasLowConfidenceFields)
                        const Text(
                          'Please review fields marked in red/orange',
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Preview image
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  _buildFieldWithConfidence(
                    label: 'Works Order No (Jobcard Number)',
                    controller: _worksOrderCtrl,
                    confidence: widget.jobcardData.worksOrderNo.confidence,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Job Name',
                    controller: _jobNameCtrl,
                    confidence: widget.jobcardData.jobName.confidence,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Color',
                    controller: _colorCtrl,
                    confidence: widget.jobcardData.color.confidence,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Cycle Weight (grams)',
                    controller: _cycleWeightCtrl,
                    confidence: widget.jobcardData.cycleWeightGrams.confidence,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Quantity to Manufacture',
                    controller: _quantityCtrl,
                    confidence:
                        widget.jobcardData.quantityToManufacture.confidence,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Daily Output',
                    controller: _dailyOutputCtrl,
                    confidence: widget.jobcardData.dailyOutput.confidence,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Target Cycle Day',
                    controller: _targetCycleDayCtrl,
                    confidence: widget.jobcardData.targetCycleDay.confidence,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Target Cycle Night',
                    controller: _targetCycleNightCtrl,
                    confidence: widget.jobcardData.targetCycleNight.confidence,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Production table data
                  if (widget.jobcardData.productionRows.isNotEmpty) ...[
                    const Text(
                      'Production Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.jobcardData.productionRows
                        .map((row) => _buildProductionRow(row)),
                    const SizedBox(height: 24),
                  ],

                  // Verification issues
                  if (widget.jobcardData.verificationNeeded.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Verification Needed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...widget.jobcardData.verificationNeeded.map(
                            (issue) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• ${issue.field}: ${issue.reason}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Create job button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _createJob,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Create Job',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionRow(ProductionTableRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date: ${row.date.value ?? "Unknown"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Day Shift',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Actual: ${row.dayActual.value ?? 0}'),
                    Text('Scrap: ${row.dayScrap.value ?? 0}'),
                    Text(
                      'Scrap Rate: ${row.dayScrapRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: row.dayScrapRate > 5 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Night Shift',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Actual: ${row.nightActual.value ?? 0}'),
                    Text('Scrap: ${row.nightScrap.value ?? 0}'),
                    Text(
                      'Scrap Rate: ${row.nightScrapRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color:
                            row.nightScrapRate > 5 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
