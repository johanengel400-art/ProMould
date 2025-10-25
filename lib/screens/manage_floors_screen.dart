import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class ManageFloorsScreen extends StatefulWidget{
  final int level; const ManageFloorsScreen({super.key, required this.level});
  @override State<ManageFloorsScreen> createState()=>_ManageFloorsScreenState();
}

class _ManageFloorsScreenState extends State<ManageFloorsScreen>{
  final uuid=const Uuid();

  Future<void> _addOrEdit({Map<String,dynamic>? floor}) async {
    final nameCtrl = TextEditingController(text: floor?['name']??'');
    final noteCtrl = TextEditingController(text: floor?['note']??'');
    await showDialog(context: context, builder: (dialogContext)=>AlertDialog(
      title: Text(floor==null? 'Add Floor' : 'Edit Floor'),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText:'Floor Name')),
        const SizedBox(height:8),
        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText:'Notes')),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final box = Hive.box('floorsBox');
          final id = floor?['id'] ?? uuid.v4();
          final data = {
            'id': id,
            'name': nameCtrl.text.trim(),
            'note': noteCtrl.text.trim(),
          };
          await box.put(id, data);
          await SyncService.pushChange('floorsBox', id, data);
          Navigator.pop(dialogContext);
        }, child: const Text('Save')),
      ],
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('floorsBox');
    final items = box.values.cast<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Floors')),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>_addOrEdit(), 
        child: const Icon(Icons.add_business)
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final f = items[i];
          return Card(child: ListTile(
            leading: const Icon(Icons.business, size: 40),
            title: Text('${f['name']}'),
            subtitle: Text('${f['note']??'No notes'}'),
            onTap: ()=>_addOrEdit(floor: Map<String,dynamic>.from(f)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline), 
              onPressed: () async {
                final floorId = f['id'] as String;
                await box.delete(floorId);
                await SyncService.deleteRemote('floorsBox', floorId);
                setState((){});
              }
            ),
          ));
        }),
    );
  }
}
