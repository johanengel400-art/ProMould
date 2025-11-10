// lib/screens/finished_jobs_screen.dart
// Comprehensive viewer for finished/archived jobs with filtering and search

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/job_status.dart';

class FinishedJobsScreen extends StatefulWidget {
  const FinishedJobsScreen({super.key});

  @override
  State<FinishedJobsScreen> createState() => _FinishedJobsScreenState();
}

class _FinishedJobsScreenState extends State<FinishedJobsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _jobs = [];
  
  // Filter options
  bool _showOverrunOnly = false;
  String _sortBy = 'finishedDate'; // finishedDate, productName, overrunAmount
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    
    try {
      final year = _selectedDate.year.toString();
      final month = _selectedDate.month.toString().padLeft(2, '0');
      final day = _selectedDate.day.toString().padLeft(2, '0');
      
      final snapshot = await _firestore
          .collection('finishedJobs')
          .doc(year)
          .collection(month)
          .doc(day)
          .collection('jobs')
          .get();
      
      _jobs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _applyFiltersAndSort();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndSort() {
    var filtered = _jobs.where((job) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final productName = (job['productName'] as String? ?? '').toLowerCase();
        final machineId = (job['machineId'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!productName.contains(query) && !machineId.contains(query)) {
          return false;
        }
      }
      
      // Overrun filter
      if (_showOverrunOnly) {
        final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
        final targetShots = job['targetShots'] as int? ?? 0;
        if (shotsCompleted <= targetShots) return false;
      }
      
      return true;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'finishedDate':
          final dateA = DateTime.tryParse(a['finishedDate'] as String? ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['finishedDate'] as String? ?? '') ?? DateTime.now();
          comparison = dateA.compareTo(dateB);
          break;
        case 'productName':
          comparison = (a['productName'] as String? ?? '').compareTo(b['productName'] as String? ?? '');
          break;
        case 'overrunAmount':
          final overrunA = JobStatus.getOverrunShots(
            a['shotsCompleted'] as int? ?? 0,
            a['targetShots'] as int? ?? 0,
          );
          final overrunB = JobStatus.getOverrunShots(
            b['shotsCompleted'] as int? ?? 0,
            b['targetShots'] as int? ?? 0,
          );
          comparison = overrunA.compareTo(overrunB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() => _jobs = filtered);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Finished Jobs'),
        backgroundColor: const Color(0xFF0F1419),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1419),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1A1F2E)),
              ),
            ),
            child: Column(
              children: [
                // Date Selector
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4CC9F0).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF4CC9F0), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFiltersAndSort();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by product or machine...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4CC9F0)),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter Chips
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Overrun Only'),
                      selected: _showOverrunOnly,
                      onSelected: (value) {
                        setState(() => _showOverrunOnly = value);
                        _applyFiltersAndSort();
                      },
                      backgroundColor: const Color(0xFF1A1F2E),
                      selectedColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                      checkmarkColor: const Color(0xFFFF6B6B),
                      labelStyle: TextStyle(
                        color: _showOverrunOnly ? const Color(0xFFFF6B6B) : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    // Sort Dropdown
                    DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: const Color(0xFF1A1F2E),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      underline: Container(),
                      icon: const Icon(Icons.sort, color: Color(0xFF4CC9F0), size: 20),
                      items: const [
                        DropdownMenuItem(value: 'finishedDate', child: Text('Date')),
                        DropdownMenuItem(value: 'productName', child: Text('Product')),
                        DropdownMenuItem(value: 'overrunAmount', child: Text('Overrun')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                          _applyFiltersAndSort();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: const Color(0xFF4CC9F0),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _sortAscending = !_sortAscending);
                        _applyFiltersAndSort();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Jobs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CC9F0)))
                : _jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No finished jobs found',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
                      ),
          ),
          
          // Summary Footer
          if (_jobs.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1419),
                border: Border(
                  top: BorderSide(color: Color(0xFF1A1F2E)),
                ),
              ),
              child: _buildSummary(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
    final targetShots = job['targetShots'] as int? ?? 0;
    final overrunShots = JobStatus.getOverrunShots(shotsCompleted, targetShots);
    final overrunPercentage = JobStatus.getOverrunPercentage(shotsCompleted, targetShots);
    final isOverrun = overrunShots > 0;
    
    final finishedDate = DateTime.tryParse(job['finishedDate'] as String? ?? '');
    final startTime = DateTime.tryParse(job['startTime'] as String? ?? '');
    
    Duration? duration;
    if (finishedDate != null && startTime != null) {
      duration = finishedDate.difference(startTime);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isOverrun ? const Color(0xFFFF6B6B) : const Color(0xFF4CC9F0)).withOpacity(0.1),
            const Color(0xFF1A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOverrun ? const Color(0xFFFF6B6B) : const Color(0xFF4CC9F0)).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isOverrun ? const Color(0xFFFF6B6B) : const Color(0xFF4CC9F0)).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOverrun ? Icons.warning : Icons.check_circle,
                    color: isOverrun ? const Color(0xFFFF6B6B) : const Color(0xFF4CC9F0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['productName'] as String? ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Machine: ${job['machineId'] as String? ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverrun)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5)),
                    ),
                    child: Text(
                      'OVERRUN',
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    '$shotsCompleted',
                    Icons.check_circle_outline,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Target',
                    '$targetShots',
                    Icons.flag_outlined,
                  ),
                ),
                if (isOverrun)
                  Expanded(
                    child: _buildStatItem(
                      'Overrun',
                      '+$overrunShots (${overrunPercentage.toStringAsFixed(1)}%)',
                      Icons.warning_outlined,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
              ],
            ),
            
            if (duration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${_formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
            
            if (finishedDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    'Finished: ${DateFormat('HH:mm').format(finishedDate)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    final itemColor = color ?? Colors.white70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: itemColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: itemColor, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: itemColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final totalJobs = _jobs.length;
    final overrunJobs = _jobs.where((j) {
      final shots = j['shotsCompleted'] as int? ?? 0;
      final target = j['targetShots'] as int? ?? 0;
      return shots > target;
    }).length;
    
    final totalShots = _jobs.fold<int>(0, (sum, j) => sum + (j['shotsCompleted'] as int? ?? 0));
    final totalTarget = _jobs.fold<int>(0, (sum, j) => sum + (j['targetShots'] as int? ?? 0));
    final totalOverrun = totalShots > totalTarget ? totalShots - totalTarget : 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('Total Jobs', '$totalJobs', Icons.work_outline),
        _buildSummaryItem('Overrun', '$overrunJobs', Icons.warning_outlined, 
          color: overrunJobs > 0 ? const Color(0xFFFF6B6B) : null),
        _buildSummaryItem('Total Shots', '$totalShots', Icons.check_circle_outline),
        if (totalOverrun > 0)
          _buildSummaryItem('Extra Shots', '+$totalOverrun', Icons.add_circle_outline,
            color: const Color(0xFFFF6B6B)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color? color}) {
    final itemColor = color ?? const Color(0xFF4CC9F0);
    return Column(
      children: [
        Icon(icon, color: itemColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: itemColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
