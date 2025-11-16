import 'dart:io';
import 'package:flutter/material.dart';
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
  late TextEditingController _fgCodeCtrl;
  late TextEditingController _dateStartedCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _dailyOutputCtrl;
  late TextEditingController _cycleTimeCtrl;
  late TextEditingController _cycleWeightCtrl;
  late TextEditingController _cavityCtrl;

  final uuid = const Uuid();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _worksOrderCtrl = TextEditingController(
      text: widget.jobcardData.worksOrderNo.value ?? '',
    );
    _fgCodeCtrl = TextEditingController(
      text: widget.jobcardData.fgCode.value ?? '',
    );
    _dateStartedCtrl = TextEditingController(
      text: widget.jobcardData.dateStarted.value ?? '',
    );
    _quantityCtrl = TextEditingController(
      text: widget.jobcardData.quantityToManufacture.value?.toString() ?? '',
    );
    _dailyOutputCtrl = TextEditingController(
      text: widget.jobcardData.dailyOutput.value?.toString() ?? '',
    );
    _cycleTimeCtrl = TextEditingController(
      text: widget.jobcardData.cycleTimeSeconds.value?.toString() ?? '',
    );
    _cycleWeightCtrl = TextEditingController(
      text: widget.jobcardData.cycleWeightGrams.value?.toString() ?? '',
    );
    _cavityCtrl = TextEditingController(
      text: widget.jobcardData.cavity.value?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _worksOrderCtrl.dispose();
    _fgCodeCtrl.dispose();
    _dateStartedCtrl.dispose();
    _quantityCtrl.dispose();
    _dailyOutputCtrl.dispose();
    _cycleTimeCtrl.dispose();
    _cycleWeightCtrl.dispose();
    _cavityCtrl.dispose();
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
      final box = Hive.box('jobsBox');
      final id = uuid.v4();

      // Create job data
      final jobData = {
        'id': id,
        'productName': _fgCodeCtrl.text.trim(),
        'color': '', // Not in jobcard
        'targetShots': int.tryParse(_quantityCtrl.text.trim()) ?? 0,
        'shotsCompleted': 0,
        'machineId': '',
        'mouldId': '',
        'status': 'Pending',
        'startTime': null,
        'endTime': null,
        // Additional jobcard fields
        'worksOrderNo': _worksOrderCtrl.text.trim(),
        'fgCode': _fgCodeCtrl.text.trim(),
        'dateStarted': _dateStartedCtrl.text.trim(),
        'dailyOutput': int.tryParse(_dailyOutputCtrl.text.trim()),
        'cycleTimeSeconds': int.tryParse(_cycleTimeCtrl.text.trim()),
        'cycleWeightGrams': double.tryParse(_cycleWeightCtrl.text.trim()),
        'cavity': int.tryParse(_cavityCtrl.text.trim()),
        'jobcardImagePath': widget.imagePath,
        'jobcardScannedAt': DateTime.now().toIso8601String(),
        'jobcardConfidence': widget.jobcardData.overallConfidence,
      };

      await box.put(id, jobData);
      await SyncService.pushChange('jobsBox', id, jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating job: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Jobcard Data'),
        actions: [
          if (widget.jobcardData.hasLowConfidenceFields)
            Padding(
              padding: const EdgeInsets.only(right: 16),
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
                    label: 'Works Order No',
                    controller: _worksOrderCtrl,
                    confidence: widget.jobcardData.worksOrderNo.confidence,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'FG Code',
                    controller: _fgCodeCtrl,
                    confidence: widget.jobcardData.fgCode.confidence,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldWithConfidence(
                    label: 'Date Started',
                    controller: _dateStartedCtrl,
                    confidence: widget.jobcardData.dateStarted.confidence,
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
                    label: 'Cycle Time (seconds)',
                    controller: _cycleTimeCtrl,
                    confidence: widget.jobcardData.cycleTimeSeconds.confidence,
                    keyboardType: TextInputType.number,
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
                    label: 'Cavity',
                    controller: _cavityCtrl,
                    confidence: widget.jobcardData.cavity.confidence,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

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
}
