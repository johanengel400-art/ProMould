// Daily Inspection Tracking for Management
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class DailyInspectionTrackingScreen extends StatefulWidget {
  const DailyInspectionTrackingScreen({super.key});

  @override
  State<DailyInspectionTrackingScreen> createState() =>
      _DailyInspectionTrackingScreenState();
}

class _DailyInspectionTrackingScreenState
    extends State<DailyInspectionTrackingScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedSetter;

  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen('usersBox')) {
      await Hive.openBox('usersBox');
    }
    if (!Hive.isBoxOpen('dailyInspectionsBox')) {
      await Hive.openBox('dailyInspectionsBox');
    }
    if (!Hive.isBoxOpen('machinesBox')) {
      await Hive.openBox('machinesBox');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Daily Inspection Tracking'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildSetterList(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F1419),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => setState(() =>
                selectedDate = selectedDate.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              final tomorrow = selectedDate.add(const Duration(days: 1));
              if (tomorrow
                  .isBefore(DateTime.now().add(const Duration(days: 1)))) {
                setState(() => selectedDate = tomorrow);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetterList() {
    return Expanded(
      child: FutureBuilder(
        future: _ensureBoxesOpen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final usersBox = Hive.box('usersBox');
          final inspectionsBox = Hive.box('dailyInspectionsBox');
          final machinesBox = Hive.box('machinesBox');

          // Filter for Setters only (Level 3)
          final setters = usersBox.values
              .cast<Map>()
              .where((u) => (u['level'] as int? ?? 0) == 3)
              .toList();
          final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

          if (setters.isEmpty) {
            return const Center(
                child: Text('No setters found',
                    style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: setters.length,
            itemBuilder: (context, index) {
              final setter = setters[index];
              final username = setter['username'] as String;

              final inspections = inspectionsBox.values
                  .cast<Map>()
                  .where((i) =>
                      i['inspectorUsername'] == username &&
                      i['date'] == dateKey)
                  .toList();

              final machines = machinesBox.values.cast<Map>().toList();
              final missedMachines = machines
                  .where(
                      (m) => !inspections.any((i) => i['machineId'] == m['id']))
                  .toList();

              return _buildSetterCard(
                  username, inspections, missedMachines, machines.length);
            },
          );
        },
      ),
    );
  }

  Widget _buildSetterCard(String username, List inspections,
      List missedMachines, int totalMachines) {
    final completionRate = totalMachines > 0
        ? (inspections.length / totalMachines * 100).round()
        : 0;
    final hasMissed = missedMachines.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F1419),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasMissed ? Colors.orange : Colors.green,
          child: Text(username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white)),
        ),
        title: Text(username,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${inspections.length}/$totalMachines machines inspected ($completionRate%)',
          style: TextStyle(color: hasMissed ? Colors.orange : Colors.green),
        ),
        children: [
          if (inspections.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Completed Inspections',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ...inspections.map((i) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(i['machineName'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${i['completionRate']}% complete',
                      style: const TextStyle(color: Colors.white70)),
                  trailing: Text(
                      DateFormat('HH:mm')
                          .format(DateTime.parse(i['timestamp'])),
                      style: const TextStyle(color: Colors.white54)),
                )),
          ],
          if (missedMachines.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Missed Inspections',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            ...missedMachines.map((m) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(m['name'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: const Text('Not inspected today',
                      style: TextStyle(color: Colors.orange)),
                )),
          ],
        ],
      ),
    );
  }
}
