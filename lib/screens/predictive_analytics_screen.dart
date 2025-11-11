import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class PredictiveAnalyticsScreen extends StatefulWidget {
  const PredictiveAnalyticsScreen({super.key});

  @override
  State<PredictiveAnalyticsScreen> createState() =>
      _PredictiveAnalyticsScreenState();
}

class _PredictiveAnalyticsScreenState extends State<PredictiveAnalyticsScreen> {
  Map<String, dynamic>? _predictions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  void _loadPredictions() {
    setState(() => _isLoading = true);
    final predictions = AnalyticsService.predictMachineFailures();
    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Predictive Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final predictions = _predictions?['predictions'] as List? ?? [];

    if (predictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'All machines operating normally',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'No maintenance predictions at this time',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(predictions),
        const SizedBox(height: 16),
        ...predictions.map((p) => _buildPredictionCard(p)),
      ],
    );
  }

  Widget _buildSummaryCard(List predictions) {
    final highRisk = predictions.where((p) => p['riskScore'] >= 70).length;
    final mediumRisk = predictions
        .where((p) => p['riskScore'] >= 40 && p['riskScore'] < 70)
        .length;
    final lowRisk = predictions.where((p) => p['riskScore'] < 40).length;

    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRiskIndicator('High', highRisk, Colors.red),
                _buildRiskIndicator('Medium', mediumRisk, Colors.orange),
                _buildRiskIndicator('Low', lowRisk, Colors.yellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final riskScore = prediction['riskScore'] as int;
    final color = _getRiskColor(riskScore);

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prediction['machineName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    'Risk: $riskScore%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: riskScore / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prediction['recommendation'],
                      style: TextStyle(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore >= 70) return Colors.red;
    if (riskScore >= 40) return Colors.orange;
    return Colors.yellow;
  }
}
