import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class ManageMachinesScreen extends StatefulWidget{
  final int level; const ManageMachinesScreen({super.key, required this.level});
  @override State<ManageMachinesScreen> createState()=>_ManageMachinesScreenState();
}

class _ManageMachinesScreenState extends State<ManageMachinesScreen>{
  final uuid=const Uuid();

  void _add() async {
    final nameCtrl=TextEditingController(); final tonCtrl=TextEditingController();
    await showDialog(context: context, builder: (_)=>AlertDialog(
      title: const Text('New Machine'),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller:nameCtrl, decoration: const InputDecoration(labelText:'Name')),
        const SizedBox(height:8),
        TextField(controller:tonCtrl, decoration: const InputDecoration(labelText:'Tonnage')),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final box = Hive.box('machinesBox');
          final id = uuid.v4();
          final data = {'id': id, 'name': nameCtrl.text.trim(), 'status':'Idle', 'tonnage': tonCtrl.text.trim()};
          await box.put(id, data);
          await SyncService.pushChange('machinesBox', id, data);
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('machinesBox');
    final items = box.values.cast<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Machines')),
      floatingActionButton: FloatingActionButton(onPressed:_add, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final m = items[i];
          return Card(child: ListTile(
            title: Text('${m['name']}'),
            subtitle: Text('Tonnage: ${m['tonnage']??''} • Status: ${m['status']}'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
              final machineId = m['id'] as String;
              await box.delete(machineId);
              await SyncService.deleteRemote('machinesBox', machineId);
              setState((){});
            }),
          ));
        }),
    );
  }
}
