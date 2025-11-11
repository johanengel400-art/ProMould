// lib/screens/job_analytics_screen.dart
// Comprehensive job analytics with overrun metrics and trends

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/job_status.dart';

class JobAnalyticsScreen extends StatefulWidget {
  const JobAnalyticsScreen({super.key});

  @override
  State<JobAnalyticsScreen> createState() => _JobAnalyticsScreenState();
}

class _JobAnalyticsScreenState extends State<JobAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final allJobs = <Map<String, dynamic>>[];

      // Load finished jobs from date range
      for (var date = _startDate;
          date.isBefore(_endDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        final year = date.year.toString();
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');

        try {
          final snapshot = await _firestore
              .collection('finishedJobs')
              .doc(year)
              .collection(month)
              .doc(day)
              .collection('jobs')
              .get();

          allJobs.addAll(snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }));
        } catch (e) {
          // Day might not exist, continue
        }
      }

      // Also include active jobs
      final jobsBox = Hive.box('jobsBox');
      final activeJobs = jobsBox.values.cast<Map>().where((j) {
        final status = j['status'] as String?;
        return JobStatus.isActive(status);
      }).toList();

      allJobs.addAll(activeJobs.map((j) => Map<String, dynamic>.from(j)));

      // Calculate analytics
      _analytics = _calculateAnalytics(allJobs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) {
      return {
        'totalJobs': 0,
        'overrunJobs': 0,
        'overrunRate': 0.0,
        'totalShots': 0,
        'totalTarget': 0,
        'totalOverrun': 0,
        'avgOverrunPercentage': 0.0,
        'machineOverruns': <String, int>{},
        'productOverruns': <String, int>{},
        'dailyTrend': <String, Map<String, int>>{},
        'worstOffenders': <Map<String, dynamic>>[],
      };
    }

    final totalJobs = jobs.length;
    var overrunJobs = 0;
    var totalShots = 0;
    var totalTarget = 0;
    var totalOverrun = 0;
    var totalOverrunPercentage = 0.0;

    final machineOverruns = <String, int>{};
    final productOverruns = <String, int>{};
    final dailyTrend = <String, Map<String, int>>{};
    final overrunDetails = <Map<String, dynamic>>[];

    for (final job in jobs) {
      final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
      final targetShots = job['targetShots'] as int? ?? 0;
      final overrunShots =
          JobStatus.getOverrunShots(shotsCompleted, targetShots);

      totalShots += shotsCompleted;
      totalTarget += targetShots;

      if (overrunShots > 0) {
        overrunJobs++;
        totalOverrun += overrunShots;

        final percentage =
            JobStatus.getOverrunPercentage(shotsCompleted, targetShots);
        totalOverrunPercentage += percentage;

        // Track by machine
        final machineId = job['machineId'] as String? ?? 'Unknown';
        machineOverruns[machineId] = (machineOverruns[machineId] ?? 0) + 1;

        // Track by product
        final productName = job['productName'] as String? ?? 'Unknown';
        productOverruns[productName] = (productOverruns[productName] ?? 0) + 1;

        // Store details for worst offenders
        overrunDetails.add({
          'job': job,
          'overrunShots': overrunShots,
          'overrunPercentage': percentage,
        });
      }

      // Daily trend
      final dateStr =
          job['finishedDate'] as String? ?? job['startTime'] as String?;
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final dayKey = DateFormat('yyyy-MM-dd').format(date);
          dailyTrend[dayKey] = dailyTrend[dayKey] ?? {'total': 0, 'overrun': 0};
          dailyTrend[dayKey]!['total'] =
              (dailyTrend[dayKey]!['total'] ?? 0) + 1;
          if (overrunShots > 0) {
            dailyTrend[dayKey]!['overrun'] =
                (dailyTrend[dayKey]!['overrun'] ?? 0) + 1;
          }
        }
      }
    }

    // Sort worst offenders
    overrunDetails.sort((a, b) => (b['overrunPercentage'] as double)
        .compareTo(a['overrunPercentage'] as double));

    return {
      'totalJobs': totalJobs,
      'overrunJobs': overrunJobs,
      'overrunRate': totalJobs > 0 ? (overrunJobs / totalJobs * 100) : 0.0,
      'totalShots': totalShots,
      'totalTarget': totalTarget,
      'totalOverrun': totalOverrun,
      'avgOverrunPercentage':
          overrunJobs > 0 ? (totalOverrunPercentage / overrunJobs) : 0.0,
      'machineOverruns': machineOverruns,
      'productOverruns': productOverruns,
      'dailyTrend': dailyTrend,
      'worstOffenders': overrunDetails.take(5).toList(),
    };
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4CC9F0),
              surface: Color(0xFF1A1F2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Job Analytics'),
        backgroundColor: const Color(0xFF0F1419),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CC9F0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF4CC9F0).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF4CC9F0), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Overview Cards
                  _buildOverviewSection(),
                  const SizedBox(height: 20),

                  // Overrun Rate Card
                  _buildOverrunRateCard(),
                  const SizedBox(height: 20),

                  // Machine Breakdown
                  _buildMachineBreakdown(),
                  const SizedBox(height: 20),

                  // Product Breakdown
                  _buildProductBreakdown(),
                  const SizedBox(height: 20),

                  // Daily Trend
                  _buildDailyTrend(),
                  const SizedBox(height: 20),

                  // Worst Offenders
                  _buildWorstOffenders(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    final totalJobs = _analytics['totalJobs'] as int? ?? 0;
    final overrunJobs = _analytics['overrunJobs'] as int? ?? 0;
    final totalShots = _analytics['totalShots'] as int? ?? 0;
    final totalOverrun = _analytics['totalOverrun'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Jobs',
                '$totalJobs',
                Icons.work_outline,
                const Color(0xFF4CC9F0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overrun Jobs',
                '$overrunJobs',
                Icons.warning_outlined,
                const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Shots',
                '$totalShots',
                Icons.check_circle_outline,
                const Color(0xFF06D6A0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Extra Shots',
                '+$totalOverrun',
                Icons.add_circle_outline,
                const Color(0xFFFFD166),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            const Color(0xFF1A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverrunRateCard() {
    final overrunRate = _analytics['overrunRate'] as double? ?? 0.0;
    final avgOverrunPercentage =
        _analytics['avgOverrunPercentage'] as double? ?? 0.0;

    final rateColor = overrunRate > 30
        ? const Color(0xFFFF6B6B)
        : overrunRate > 15
            ? const Color(0xFFFFD166)
            : const Color(0xFF06D6A0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rateColor.withOpacity(0.15),
            const Color(0xFF1A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rateColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: rateColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: rateColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overrun Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${overrunRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: rateColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avg Overrun Amount',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${avgOverrunPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: rateColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: rateColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  overrunRate > 30
                      ? 'HIGH'
                      : overrunRate > 15
                          ? 'MODERATE'
                          : 'LOW',
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMachineBreakdown() {
    final machineOverruns =
        _analytics['machineOverruns'] as Map<String, int>? ?? {};
    if (machineOverruns.isEmpty) return const SizedBox.shrink();

    final sortedMachines = machineOverruns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overruns by Machine',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sortedMachines.take(5).map((entry) => _buildBarItem(
              entry.key,
              entry.value,
              sortedMachines.first.value,
              const Color(0xFF4CC9F0),
            )),
      ],
    );
  }

  Widget _buildProductBreakdown() {
    final productOverruns =
        _analytics['productOverruns'] as Map<String, int>? ?? {};
    if (productOverruns.isEmpty) return const SizedBox.shrink();

    final sortedProducts = productOverruns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overruns by Product',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sortedProducts.take(5).map((entry) => _buildBarItem(
              entry.key,
              entry.value,
              sortedProducts.first.value,
              const Color(0xFFFFD166),
            )),
      ],
    );
  }

  Widget _buildBarItem(String label, int value, int maxValue, Color color) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrend() {
    final dailyTrend =
        _analytics['dailyTrend'] as Map<String, Map<String, int>>? ?? {};
    if (dailyTrend.isEmpty) return const SizedBox.shrink();

    final sortedDays = dailyTrend.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Trend',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: sortedDays.map((entry) {
              final date = DateTime.parse(entry.key);
              final total = entry.value['total'] ?? 0;
              final overrun = entry.value['overrun'] ?? 0;
              final rate = total > 0 ? (overrun / total * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        DateFormat('MMM d').format(date),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$total jobs',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white54),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$overrun overrun',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFFF6B6B)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${rate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: rate > 30
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF06D6A0),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWorstOffenders() {
    final worstOffenders = _analytics['worstOffenders'] as List? ?? [];
    if (worstOffenders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Worst Overruns',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...worstOffenders.map((offender) {
          final job = offender['job'] as Map<String, dynamic>;
          final overrunShots = offender['overrunShots'] as int;
          final overrunPercentage = offender['overrunPercentage'] as double;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.15),
                  const Color(0xFF1A1F2E),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job['productName'] as String? ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${overrunPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.precision_manufacturing,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      job['machineId'] as String? ?? 'Unknown',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.add_circle_outline,
                        size: 14, color: const Color(0xFFFF6B6B)),
                    const SizedBox(width: 4),
                    Text(
                      '+$overrunShots shots',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFFF6B6B)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
