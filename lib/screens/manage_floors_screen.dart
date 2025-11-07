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
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        }, child: const Text('Save')),
      ],
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('floorsBox');
    final items = box.values.cast<Map>().toList();
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
              title: const Text('Floors'),
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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_,i){
                  final f = items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFF0F1419),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CC9F0).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business, color: Color(0xFF4CC9F0)),
                      ),
                      title: Text('${f['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${f['note']??'No notes'}', style: const TextStyle(color: Colors.white70)),
                      onTap: ()=>_addOrEdit(floor: Map<String,dynamic>.from(f)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red), 
                        onPressed: () async {
                          final floorId = f['id'] as String;
                          await box.delete(floorId);
                          await SyncService.deleteRemote('floorsBox', floorId);
                          setState((){});
                        }
                      ),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ()=>_addOrEdit(),
        backgroundColor: const Color(0xFF4CC9F0),
        icon: const Icon(Icons.add),
        label: const Text('Add Floor'),
      ),
    );
  }
}
