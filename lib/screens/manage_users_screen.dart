import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class ManageUsersScreen extends StatefulWidget{
  final int level; const ManageUsersScreen({super.key, required this.level});
  @override State<ManageUsersScreen> createState()=>_ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>{
  final uuid=const Uuid();
  final levels = const {1:'Operator',2:'Material',3:'Setter',4:'Management'};

  Future<void> _addOrEdit({Map<String,dynamic>? user}) async {
    final uCtrl = TextEditingController(text: user?['username']??'');
    final pCtrl = TextEditingController(text: user?['password']??'');
    int level = (user?['level']??1) as int;
    String shift = user?['shift']??'Day';

    await showDialog(context: context, builder: (dialogContext)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(user==null? 'Add User' : 'Edit User'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller: uCtrl, decoration: const InputDecoration(labelText:'Username')),
          const SizedBox(height:8),
          TextField(controller: pCtrl, decoration: const InputDecoration(labelText:'Password'), obscureText: true),
          const SizedBox(height:8),
          DropdownButtonFormField<int>(
            value: level,
            items: levels.entries.map((e)=>DropdownMenuItem(value:e.key, child: Text('${e.key} • ${e.value}'))).toList(),
            onChanged: (v)=> setDialogState(()=>level = v ?? 1), 
            decoration: const InputDecoration(labelText:'Level')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: shift,
            items: const ['Day','Night','Any'].map((s)=>DropdownMenuItem(value:s, child: Text(s))).toList(),
            onChanged: (v)=> setDialogState(()=>shift = v ?? 'Day'), 
            decoration: const InputDecoration(labelText:'Shift')),
        ])),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final box = Hive.box('usersBox');
            final id = user?['id'] ?? uuid.v4();
            final data = {
              'id': id,
              'username': uCtrl.text.trim(),
              'password': pCtrl.text,
              'level': level,
              'shift': shift,
            };
            await box.put(id, data);
            await SyncService.pushChange('usersBox', id, data);
            Navigator.pop(dialogContext);
          }, child: const Text('Save')),
        ],
      ),
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('usersBox');
    final items = box.values.cast<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>_addOrEdit(), 
        child: const Icon(Icons.person_add_alt_1)
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final u = items[i];
          final levelName = levels[u['level']] ?? 'Unknown';
          return Card(child: ListTile(
            leading: CircleAvatar(
              child: Text('${u['username']}'.substring(0,1).toUpperCase()),
            ),
            title: Text('${u['username']}'),
            subtitle: Text('Level: ${u['level']} ($levelName) • Shift: ${u['shift']}'),
            onTap: ()=>_addOrEdit(user: Map<String,dynamic>.from(u)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline), 
              onPressed: () async {
                // Prevent deleting the last admin
                if(u['level'] == 4) {
                  final adminCount = items.where((item) => item['level'] == 4).length;
                  if(adminCount <= 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot delete the last admin user'))
                    );
                    return;
                  }
                }
                final userId = u['id'] as String;
                await box.delete(userId);
                await SyncService.deleteRemote('usersBox', userId);
                setState((){});
              }
            ),
          ));
        }),
    );
  }
}
