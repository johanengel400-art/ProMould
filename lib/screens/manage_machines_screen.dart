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
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Machines'),
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
                  final m = items[i];
                  final floorName = floors[m['floorId']] ?? 'No Floor';
                  final status = m['status'] ?? 'Idle';
                  final statusColor = status == 'Running' ? const Color(0xFF4CC9F0) :
                                     status == 'Breakdown' ? const Color(0xFFEF476F) :
                                     const Color(0xFFFFD166);
                  
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
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.precision_manufacturing, color: statusColor),
                      ),
                      title: Text('${m['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Floor: $floorName', style: const TextStyle(color: Colors.white70)),
                          Text('Tonnage: ${m['tonnage']??'N/A'}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white38),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _edit(m);
                          } else if (value == 'delete') {
                            final machineId = m['id'] as String;
                            await box.delete(machineId);
                            await SyncService.deleteRemote('machinesBox', machineId);
                            setState((){});
                          }
                        },
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
        onPressed:_add,
        backgroundColor: const Color(0xFF4CC9F0),
        icon: const Icon(Icons.add),
        label: const Text('Add Machine'),
      ),
    );
  }
}
