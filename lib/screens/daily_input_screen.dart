import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class DailyInputScreen extends StatefulWidget{
  final String username; final int level;
  const DailyInputScreen({super.key, required this.username, required this.level});
  @override State<DailyInputScreen> createState()=>_DailyInputScreenState();
}

class _DailyInputScreenState extends State<DailyInputScreen>{
  final uuid=const Uuid(); String? machineId; Map? job;
  final shotsCtrl=TextEditingController(); final scrapCtrl=TextEditingController();
  String scrapReason='Other'; final reasons=['Short Shot','Flash','Burn','Contamination','Color Variation','Other'];

  void _save() async {
    final shots=int.tryParse(shotsCtrl.text.trim())??0;
    final scrap=int.tryParse(scrapCtrl.text.trim())??0;
    if(machineId==null){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a machine'))); return; }
    final inputs = Hive.box('inputsBox');
    final id = uuid.v4();
    final data = {
      'id': id,
      'machineId': machineId!,
      'jobId': job?['id'] ?? '',
      'date': DateTime.now().toIso8601String(),
      'shots': shots,
      'scrap': scrap,
      'scrapReason': scrapReason,
      'notes': '',
    };
    await inputs.put(id, data);
    await SyncService.pushChange('inputsBox', id, data);

    if(job!=null){
      final jobsBox = Hive.box('jobsBox');
      final jobId = job!['id'] as String;
      final updated = Map<String,dynamic>.from(job!);
      updated['shotsCompleted'] = (updated['shotsCompleted'] ?? 0) + shots;
      if((updated['shotsCompleted'] ?? 0) >= (updated['targetShots'] ?? 0)){
        updated['status']='Finished'; 
        updated['endTime']=DateTime.now().toIso8601String();
      }
      await jobsBox.put(jobId, updated);
      await SyncService.pushChange('jobsBox', jobId, updated);
    }

    shotsCtrl.clear(); scrapCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved.')));
  }

  @override Widget build(BuildContext context){
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');

    final machines = machinesBox.values.cast<Map>().toList();
    final jobsForMachine = jobsBox.values.cast<Map>()
      .where((j)=> j['machineId']==machineId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Inputs')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children:[
          DropdownButtonFormField<String>(
            value: machineId ?? (machines.isNotEmpty? machines.first['id'] as String: null),
            items: machines.map((m)=>DropdownMenuItem<String>(value:m['id'] as String, child: Text('${m['name']}'))).toList(),
            onChanged: (v)=>setState(()=>machineId=v),
            decoration: const InputDecoration(labelText:'Machine'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Map>(
            value: job,
            items: jobsForMachine.map((j)=>DropdownMenuItem(value:j, child: Text('${j['productName']} • ${j['color']??''}'))).toList(),
            onChanged: (v)=>setState(()=>job=v),
            decoration: const InputDecoration(labelText:'Job (optional)'),
          ),
          const SizedBox(height: 10),
          Row(children:[
            Expanded(child: TextField(controller: shotsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Good Shots'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: scrapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Scrap'))),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: scrapReason,
            items: reasons.map((s)=>DropdownMenuItem(value:s, child: Text(s))).toList(),
            onChanged: (v)=>setState(()=>scrapReason=v??'Other'),
            decoration: const InputDecoration(labelText:'Scrap Reason'),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed:_save, child: const Text('Save Entry'))),
        ]),
      ),
    );
  }
}
