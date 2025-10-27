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
    final nameCtrl=TextEditingController(); 
    final tonCtrl=TextEditingController();
    final floorsBox = Hive.box('floorsBox');
    final floors = floorsBox.values.cast<Map>().toList();
    String? selectedFloor = floors.isNotEmpty ? floors.first['id'] as String : null;
    
    await showDialog(context: context, builder: (_)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('New Machine'),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:nameCtrl, decoration: const InputDecoration(labelText:'Name')),
          const SizedBox(height:8),
          TextField(controller:tonCtrl, decoration: const InputDecoration(labelText:'Tonnage')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: selectedFloor,
            items: floors.map((f)=>DropdownMenuItem<String>(
              value:f['id'] as String, 
              child: Text('${f['name']}')
            )).toList(),
            onChanged: (v)=>setDialogState(()=>selectedFloor=v),
            decoration: const InputDecoration(labelText:'Floor'),
          ),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final box = Hive.box('machinesBox');
            final id = uuid.v4();
            final data = {
              'id': id, 
              'name': nameCtrl.text.trim(), 
              'status':'Idle', 
              'tonnage': tonCtrl.text.trim(),
              'floorId': selectedFloor ?? '',
            };
            await box.put(id, data);
            await SyncService.pushChange('machinesBox', id, data);
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    ));
    setState((){});
  }

  void _edit(Map m) async {
    final nameCtrl=TextEditingController(text: m['name'] as String?); 
    final tonCtrl=TextEditingController(text: m['tonnage'] as String?);
    final floorsBox = Hive.box('floorsBox');
    final floors = floorsBox.values.cast<Map>().toList();
    String? selectedFloor = m['floorId'] as String?;
    
    await showDialog(context: context, builder: (_)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit Machine'),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:nameCtrl, decoration: const InputDecoration(labelText:'Name')),
          const SizedBox(height:8),
          TextField(controller:tonCtrl, decoration: const InputDecoration(labelText:'Tonnage')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: selectedFloor,
            items: floors.map((f)=>DropdownMenuItem<String>(
              value:f['id'] as String, 
              child: Text('${f['name']}')
            )).toList(),
            onChanged: (v)=>setDialogState(()=>selectedFloor=v),
            decoration: const InputDecoration(labelText:'Floor'),
          ),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final box = Hive.box('machinesBox');
            final machineId = m['id'] as String;
            final data = Map<String,dynamic>.from(m);
            data['name'] = nameCtrl.text.trim();
            data['tonnage'] = tonCtrl.text.trim();
            data['floorId'] = selectedFloor ?? '';
            await box.put(machineId, data);
            await SyncService.pushChange('machinesBox', machineId, data);
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('machinesBox');
    final floorsBox = Hive.box('floorsBox');
    final items = box.values.cast<Map>().toList();
    final floors = {for(final f in floorsBox.values.cast<Map>()) f['id']: f['name']};
    
    return Scaffold(
      appBar: AppBar(title: const Text('Machines')),
      floatingActionButton: FloatingActionButton(onPressed:_add, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final m = items[i];
          final floorName = floors[m['floorId']] ?? 'No Floor';
          return Card(child: ListTile(
            title: Text('${m['name']}'),
            subtitle: Text('Floor: $floorName • Tonnage: ${m['tonnage']??''} • Status: ${m['status']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Machine',
                  onPressed: () => _edit(m),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Machine',
                  onPressed: () async {
                    final machineId = m['id'] as String;
                    await box.delete(machineId);
                    await SyncService.deleteRemote('machinesBox', machineId);
                    setState((){});
                  },
                ),
              ],
            ),
          ));
        }),
    );
  }
}
