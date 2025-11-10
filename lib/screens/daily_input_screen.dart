import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';
import '../services/live_progress_service.dart';

class DailyInputScreen extends StatefulWidget{
  final String username; final int level;
  const DailyInputScreen({super.key, required this.username, required this.level});
  @override State<DailyInputScreen> createState()=>_DailyInputScreenState();
}

class _DailyInputScreenState extends State<DailyInputScreen>{
  final uuid=const Uuid(); String? machineId; Map? job;
  final shotsCtrl=TextEditingController(); final scrapCtrl=TextEditingController();
  String scrapReason='Other'; final reasons=['Short Shot','Flash','Burn','Contamination','Color Variation','Other'];
  bool isAddMode = true; // true = Add to count, false = Set count

  void _save() async {
    final shots=int.tryParse(shotsCtrl.text.trim())??0;
    final scrap=int.tryParse(scrapCtrl.text.trim())??0;
    if(machineId==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a machine'))); return; }
    
    final inputs = Hive.box('inputsBox');
    final id = uuid.v4();
    
    // Calculate actual shots to record based on mode
    int shotsToRecord = shots;
    if (!isAddMode && job != null) {
      // Set mode: calculate difference from current count
      final currentShots = (job!['shotsCompleted'] ?? 0) as int;
      shotsToRecord = shots - currentShots;
    }
    
    final data = {
      'id': id,
      'machineId': machineId!,
      'jobId': job?['id'] ?? '',
      'date': DateTime.now().toIso8601String(),
      'shots': shotsToRecord,
      'scrap': scrap,
      'scrapReason': scrapReason,
      'notes': isAddMode ? '' : 'Set to $shots',
    };
    await inputs.put(id, data);
    await SyncService.pushChange('inputsBox', id, data);

    if(job!=null){
      final jobId = job!['id'] as String;
      final jobsBox = Hive.box('jobsBox');
      final updated = Map<String,dynamic>.from(job!);
      
      // Update total based on mode
      final newTotal = isAddMode 
        ? (updated['shotsCompleted'] ?? 0) + shots
        : shots; // Set mode: use the value directly
      
      updated['shotsCompleted'] = newTotal;
      
      // Check if target shots reached and change status to Overrunning
      final targetShots = (updated['targetShots'] ?? 0) as int;
      if (newTotal >= targetShots && updated['status'] == 'Running') {
        updated['status'] = 'Overrunning';
        updated['overrunStartTime'] = DateTime.now().toIso8601String();
      }
      
      // Save updated job
      await jobsBox.put(jobId, updated);
      await SyncService.pushChange('jobsBox', jobId, updated);
      
      // Record manual input to reset the live progress baseline
      await LiveProgressService.recordManualInput(jobId, newTotal);
      
      // NO AUTO-STOP: Job continues running even past target
      // User must manually stop the job
    }

    shotsCtrl.clear(); scrapCtrl.clear();
    final modeText = isAddMode ? 'Added $shots shots' : 'Set to $shots shots';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$modeText. Live progress reset to actual count.')));
    }
  }

  @override Widget build(BuildContext context){
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');

    final machines = machinesBox.values.cast<Map>().toList();
    final jobsForMachine = jobsBox.values.cast<Map>()
      .where((j)=> j['machineId']==machineId).toList();

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
              title: const Text('Daily Inputs'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CC9F0).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Card(
                color: const Color(0xFF0F1419),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Record Production',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAddMode ? const Color(0xFF06D6A0) : const Color(0xFF4CC9F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAddMode ? Icons.add : Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAddMode ? 'ADD' : 'SET',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Add to Count'),
                            icon: Icon(Icons.add_circle_outline),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('Set Count'),
                            icon: Icon(Icons.edit_outlined),
                          ),
                        ],
                        selected: {isAddMode},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            isAddMode = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return isAddMode ? const Color(0xFF06D6A0) : const Color(0xFF4CC9F0);
                            }
                            return Colors.transparent;
                          }),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: machineId ?? (machines.isNotEmpty? machines.first['id'] as String: null),
                        dropdownColor: const Color(0xFF0F1419),
                        style: const TextStyle(color: Colors.white),
                        items: machines.map((m)=>DropdownMenuItem<String>(
                          value:m['id'] as String, 
                          child: Text('${m['name']}')
                        )).toList(),
                        onChanged: (v)=>setState(()=>machineId=v),
                        decoration: InputDecoration(
                          labelText:'Machine',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CC9F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Map>(
                        value: job,
                        dropdownColor: const Color(0xFF0F1419),
                        style: const TextStyle(color: Colors.white),
                        items: jobsForMachine.map((j)=>DropdownMenuItem(
                          value:j, 
                          child: Text('${j['productName']} • ${j['color']??''}')
                        )).toList(),
                        onChanged: (v)=>setState(()=>job=v),
                        decoration: InputDecoration(
                          labelText:'Job (optional)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CC9F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (job != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAddMode 
                                    ? 'Current: ${job!['shotsCompleted'] ?? 0} • Enter shots to ADD'
                                    : 'Current: ${job!['shotsCompleted'] ?? 0} • Enter new total to SET',
                                  style: TextStyle(fontSize: 12, color: Colors.blue[300]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (job != null) const SizedBox(height: 16),
                      Row(children:[
                        Expanded(
                          child: TextField(
                            controller: shotsCtrl, 
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: isAddMode ? 'Good Shots (Add)' : 'Good Shots (Set Total)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF06D6A0)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: scrapCtrl, 
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText:'Scrap',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFEF476F)),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: scrapReason,
                        dropdownColor: const Color(0xFF0F1419),
                        style: const TextStyle(color: Colors.white),
                        items: reasons.map((s)=>DropdownMenuItem(value:s, child: Text(s))).toList(),
                        onChanged: (v)=>setState(()=>scrapReason=v??'Other'),
                        decoration: InputDecoration(
                          labelText:'Scrap Reason',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CC9F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, 
                        height: 50,
                        child: ElevatedButton(
                          onPressed:_save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CC9F0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Entry',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
