import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class PlanningScreen extends StatefulWidget{
  final int level; const PlanningScreen({super.key, required this.level});
  @override State<PlanningScreen> createState()=>_PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>{
  final uuid=const Uuid();
  String? selectedFloorId;

  @override Widget build(BuildContext context){
    final floorsBox = Hive.box('floorsBox');
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    final queueBox = Hive.box('queueBox');

    final floors = floorsBox.values.cast<Map>().toList();
    final floorId = selectedFloorId ?? (floors.isNotEmpty ? floors.first['id'] as String : null);

    final machines = machinesBox.values.cast<Map>().where((m)=> (m['floorId']??'') == (floorId??'')).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Production Planning')),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[
          Expanded(child: DropdownButtonFormField<String>(
            value: floorId,
            items: floors.map((f)=>DropdownMenuItem(value:f['id'] as String, child: Text('${f['name']}'))).toList(),
            onChanged: (v)=>setState(()=>selectedFloorId=v),
            decoration: const InputDecoration(labelText:'Floor'),
          )),
          const SizedBox(width:12),
          ElevatedButton.icon(onPressed: _addJobToMachine, icon: const Icon(Icons.add), label: const Text('Assign Job')),
        ])),
        const Divider(height:1),
        Expanded(child: ListView.builder(
          itemCount: machines.length,
          itemBuilder: (_,i){
            final m = machines[i];
            final q = queueBox.values.cast<Map>().where((e)=> e['machineId']==m['id']).toList()
              ..sort((a,b)=> (a['order'] as int).compareTo(b['order'] as int));
            final running = jobsBox.values.cast<Map?>().firstWhere(
              (j)=> j!=null && j!['machineId']==m['id'] && j!['status']=='Running',
              orElse: ()=>null);
            return Card(child: ExpansionTile(
              title: Text('${m['name']} • ${m['status']}'),
              subtitle: Text(running==null? 'No active job' : 'Running: ${running['productName']} • ${running['shotsCompleted']}/${running['targetShots']}'),
              children: [
                if(q.isEmpty) const ListTile(title: Text('No queued jobs')),
                for(final qi in q) ListTile(
                  leading: CircleAvatar(child: Text('${qi['order']}')),
                  title: Text('Job: ${qi['jobName']??qi['jobId']}'),
                  trailing: Wrap(spacing:6, children:[
                    IconButton(onPressed: ()=>_reorder(qi,-1), icon: const Icon(Icons.expand_less)),
                    IconButton(onPressed: ()=>_reorder(qi, 1), icon: const Icon(Icons.expand_more)),
                    IconButton(onPressed: ()=>_removeQueue(qi), icon: const Icon(Icons.delete_outline)),
                  ]),
                ),
              ],
            ));
          })),
      ]),
    );
  }

  Future<void> _removeQueue(Map qi) async {
    final qBox = Hive.box('queueBox');
    final queueId = qi['id'] as String;
    await qBox.delete(queueId);
    await SyncService.deleteRemote('queueBox', queueId);
    setState((){});
  }

  Future<void> _reorder(Map qi, int delta) async {
    final qBox = Hive.box('queueBox');
    final list = qBox.values.cast<Map>().where((e)=> e['machineId']==qi['machineId']).toList()
      ..sort((a,b)=> (a['order'] as int).compareTo(b['order'] as int));
    final idx = list.indexWhere((e)=> e['id']==qi['id']);
    final newIdx = (idx + delta).clamp(0, list.length-1);
    if(idx==newIdx) return;
    
    final swap = list[newIdx];
    final qiId = qi['id'] as String;
    final swapId = swap['id'] as String;
    
    // Swap orders
    final tempOrder = qi['order'];
    qi['order'] = swap['order'];
    swap['order'] = tempOrder;
    
    // Update both in Hive and Firebase
    await qBox.put(qiId, qi);
    await qBox.put(swapId, swap);
    await SyncService.pushChange('queueBox', qiId, Map<String, dynamic>.from(qi));
    await SyncService.pushChange('queueBox', swapId, Map<String, dynamic>.from(swap));
    
    setState((){});
  }

  Future<void> _addJobToMachine() async {
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    final queueBox = Hive.box('queueBox');

    String? machineId = machinesBox.values.cast<Map>().isNotEmpty ? machinesBox.values.cast<Map>().first['id'] as String : null;
    String? jobId = jobsBox.values.cast<Map>().isNotEmpty ? jobsBox.values.cast<Map>().first['id'] as String : null;

    await showDialog(context: context, builder: (dialogContext)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Assign Job to Machine'),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          DropdownButtonFormField<String>(
            value: machineId,
            items: machinesBox.values.cast<Map>().map((m)=>DropdownMenuItem(value:m['id'] as String, child: Text('${m['name']}'))).toList(),
            onChanged: (v)=> setDialogState(()=>machineId=v), 
            decoration: const InputDecoration(labelText:'Machine')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: jobId,
            items: jobsBox.values.cast<Map>().map((j)=>DropdownMenuItem(value:j['id'] as String, child: Text('${j['productName']}'))).toList(),
            onChanged: (v)=> setDialogState(()=>jobId=v), 
            decoration: const InputDecoration(labelText:'Job')),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if(machineId==null || jobId==null) { Navigator.pop(dialogContext); return; }
            
            final id = uuid.v4();
            final lastOrder = queueBox.values.cast<Map>().where((e)=> e['machineId']==machineId).fold<int>(0,(p,e)=> (e['order'] as int)>p? e['order'] as int : p);
            
            final job = jobsBox.values.cast<Map>().firstWhere((j)=> j['id']==jobId, orElse: ()=>{});
            final data = {
              'id':id,
              'machineId':machineId,
              'jobId':jobId,
              'jobName':job['productName']??'',
              'order': lastOrder+1
            };
            
            await queueBox.put(id, data);
            await SyncService.pushChange('queueBox', id, data);
            Navigator.pop(dialogContext);
          }, child: const Text('Add')),
        ],
      ),
    ));
    setState((){});
  }
}
