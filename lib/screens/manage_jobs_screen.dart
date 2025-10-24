import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class ManageJobsScreen extends StatefulWidget{
  final int level; const ManageJobsScreen({super.key, required this.level});
  @override State<ManageJobsScreen> createState()=>_ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen>{
  final uuid=const Uuid();

  void _add() async {
    final productCtrl=TextEditingController();
    final colorCtrl=TextEditingController();
    final targetCtrl=TextEditingController();
    String? selectedMachine;
    
    final machinesBox = Hive.box('machinesBox');
    final machines = machinesBox.values.cast<Map>().toList();
    
    await showDialog(context: context, builder: (_)=>AlertDialog(
      title: const Text('New Job'),
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:productCtrl, decoration: const InputDecoration(labelText:'Product Name')),
          const SizedBox(height:8),
          TextField(controller:colorCtrl, decoration: const InputDecoration(labelText:'Color')),
          const SizedBox(height:8),
          TextField(controller:targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Target Shots')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: selectedMachine,
            items: machines.map((m)=>DropdownMenuItem<String>(value:m['id'] as String, child: Text('${m['name']}'))).toList(),
            onChanged: (v)=>setDialogState(()=>selectedMachine=v),
            decoration: const InputDecoration(labelText:'Machine'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: (){
          final box = Hive.box('jobsBox');
          final id = uuid.v4();
          box.add({
            'id': id,
            'productName': productCtrl.text.trim(),
            'color': colorCtrl.text.trim(),
            'targetShots': int.tryParse(targetCtrl.text.trim()) ?? 0,
            'shotsCompleted': 0,
            'machineId': selectedMachine ?? '',
            'status': 'Queued',
            'startTime': null,
            'endTime': null,
            'eta': null,
          });
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('jobsBox');
    final items = box.values.cast<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      floatingActionButton: FloatingActionButton(onPressed:_add, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final j = items[i];
          final progress = (j['targetShots'] ?? 0) > 0 
            ? ((j['shotsCompleted'] ?? 0) / (j['targetShots'] ?? 1) * 100).round()
            : 0;
          return Card(child: ListTile(
            title: Text('${j['productName']} • ${j['color']??''}'),
            subtitle: Text('Status: ${j['status']} • Progress: $progress%'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: (){
              final key = box.keys.elementAt(i); box.delete(key); setState((){});
            }),
          ));
        }),
    );
  }
}
