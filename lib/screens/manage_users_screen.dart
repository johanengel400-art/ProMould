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
    String? assignedMachineId = user?['assignedMachineId'] as String?;
    String? assignedFloorId = user?['assignedFloorId'] as String?;
    
    final machinesBox = Hive.box('machinesBox');
    final machines = machinesBox.values.cast<Map>().toList();
    final floorsBox = Hive.box('floorsBox');
    final floors = floorsBox.values.cast<Map>().toList();

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
          const SizedBox(height:8),
          if (level == 1) ...[
            const Divider(),
            const Text('Operator Machine Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            DropdownButtonFormField<String?>(
              value: assignedMachineId,
              items: [
                const DropdownMenuItem(value: null, child: Text('No Assignment (See All)')),
                ...machines.map((m)=>DropdownMenuItem(
                  value: m['id'] as String, 
                  child: Text(m['name'] as String)
                )),
              ],
              onChanged: (v)=> setDialogState(()=>assignedMachineId = v), 
              decoration: const InputDecoration(
                labelText:'Assigned Machine',
                helperText: 'Operators only see their assigned machine',
              ),
            ),
          ],
          if (level >= 2 && level <= 3) ...[
            const Divider(),
            const Text('Setter/Material Floor Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            DropdownButtonFormField<String?>(
              value: assignedFloorId,
              items: [
                const DropdownMenuItem(value: null, child: Text('No Assignment (All Floors)')),
                ...floors.map((f)=>DropdownMenuItem(
                  value: f['id'] as String, 
                  child: Text(f['name'] as String)
                )),
              ],
              onChanged: (v)=> setDialogState(()=>assignedFloorId = v), 
              decoration: const InputDecoration(
                labelText:'Assigned Floor',
                helperText: 'Setters see only machines on their floor',
              ),
            ),
          ],
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
              'assignedMachineId': level == 1 ? assignedMachineId : null,
              'assignedFloorId': (level >= 2 && level <= 3) ? assignedFloorId : null,
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
    
    // Group users by level for better organization
    final operators = items.where((u) => u['level'] == 1).length;
    final material = items.where((u) => u['level'] == 2).length;
    final setters = items.where((u) => u['level'] == 3).length;
    final management = items.where((u) => u['level'] == 4).length;
    
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
              title: const Text('Users'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9D4EDD).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Stats cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard('Operators', operators.toString(), const Color(0xFF4CC9F0))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Material', material.toString(), const Color(0xFF06D6A0))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Setters', setters.toString(), const Color(0xFFFFD166))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Mgmt', management.toString(), const Color(0xFF9D4EDD))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_,i){
                  final u = items[i];
                  final levelName = levels[u['level']] ?? 'Unknown';
                  final levelColor = _getLevelColor(u['level'] as int);
                  
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
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${u['username']}'.substring(0,1).toUpperCase(),
                            style: TextStyle(
                              color: levelColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text('${u['username']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: levelColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: levelColor.withOpacity(0.5)),
                                ),
                                child: Text(
                                  'Level ${u['level']} • $levelName',
                                  style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${u['shift']} Shift',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          if (u['level'] == 1 && u['assignedMachineId'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.precision_manufacturing, size: 12, color: Color(0xFF4CC9F0)),
                                const SizedBox(width: 4),
                                Text(
                                  'Machine: ${_getMachineName(u['assignedMachineId'] as String)}',
                                  style: const TextStyle(color: Color(0xFF4CC9F0), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                          if ((u['level'] == 2 || u['level'] == 3) && u['assignedFloorId'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.apartment, size: 12, color: Color(0xFFFFD166)),
                                const SizedBox(width: 4),
                                Text(
                                  'Floor: ${_getFloorName(u['assignedFloorId'] as String)}',
                                  style: const TextStyle(color: Color(0xFFFFD166), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      onTap: ()=>_addOrEdit(user: Map<String,dynamic>.from(u)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red), 
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
        backgroundColor: const Color(0xFF9D4EDD),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
  
  String _getMachineName(String machineId) {
    final machinesBox = Hive.box('machinesBox');
    final machine = machinesBox.get(machineId) as Map?;
    return machine?['name'] ?? 'Unknown';
  }
  
  String _getFloorName(String floorId) {
    final floorsBox = Hive.box('floorsBox');
    final floor = floorsBox.get(floorId) as Map?;
    return floor?['name'] ?? 'Unknown';
  }
  
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), const Color(0xFF0F1419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getLevelColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF4CC9F0); // Operator - Cyan
      case 2: return const Color(0xFF06D6A0); // Material - Green
      case 3: return const Color(0xFFFFD166); // Setter - Yellow
      case 4: return const Color(0xFF9D4EDD); // Management - Purple
      default: return Colors.white70;
    }
  }
}
