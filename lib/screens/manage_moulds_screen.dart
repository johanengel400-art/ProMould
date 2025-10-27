import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';
import '../services/photo_service.dart';

class ManageMouldsScreen extends StatefulWidget{
  final int level;
  const ManageMouldsScreen({super.key, required this.level});
  @override State<ManageMouldsScreen> createState()=>_ManageMouldsScreenState();
}

class _ManageMouldsScreenState extends State<ManageMouldsScreen>{
  final uuid=const Uuid();

  Future<void> _addOrEdit({Map<String,dynamic>? item}) async {
    final numCtrl = TextEditingController(text: item?['number']??'');
    final nameCtrl = TextEditingController(text: item?['name']??'');
    final matCtrl = TextEditingController(text: item?['material']??'');
    final cavCtrl = TextEditingController(text: item?['cavities']?.toString()??'1');
    final cycCtrl = TextEditingController(text: item?['cycleTime']?.toString()??'30');
    bool hotRunner = item?['hotRunner']==true;
    String? photoUrl = item?['photoUrl'];

    await showDialog(context: context, builder: (dialogContext)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(item==null? 'Add Mould' : 'Edit Mould'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller: numCtrl, decoration: const InputDecoration(labelText:'Mould Number')),
          const SizedBox(height:8),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText:'Name / Product')),
          const SizedBox(height:8),
          TextField(controller: matCtrl, decoration: const InputDecoration(labelText:'Material')),
          const SizedBox(height:8),
          TextField(controller: cavCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Cavities')),
          const SizedBox(height:8),
          TextField(controller: cycCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Cycle Time (s)')),
          const SizedBox(height:8),
          SwitchListTile(
            value: hotRunner, 
            onChanged:(v)=> setDialogState(()=>hotRunner=v), 
            title: const Text('Hot runner')
          ),
          const SizedBox(height:8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_camera),
            title: Text(photoUrl != null ? 'Photo attached' : 'Add photo (optional)'),
            trailing: photoUrl != null 
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setDialogState(() => photoUrl = null),
                )
              : null,
            onTap: () async {
              final tempId = item?['id'] ?? uuid.v4();
              final url = await PhotoService.uploadMouldPhoto(tempId);
              if (url != null) {
                setDialogState(() => photoUrl = url);
              }
            },
          ),
        ])),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final box = Hive.box('mouldsBox');
            final id = item?['id'] ?? uuid.v4();
            final data = {
              'id': id,
              'number': numCtrl.text.trim(),
              'name': nameCtrl.text.trim(),
              'material': matCtrl.text.trim(),
              'cavities': int.tryParse(cavCtrl.text.trim())??1,
              'cycleTime': double.tryParse(cycCtrl.text.trim())??30.0,
              'hotRunner': hotRunner,
              'status': item?['status']??'Available',
              if (photoUrl != null) 'photoUrl': photoUrl,
            };
            await box.put(id, data);
            await SyncService.pushChange('mouldsBox', id, data);
            Navigator.pop(dialogContext);
          }, child: const Text('Save')),
        ],
      ),
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('mouldsBox');
    final items = box.values.cast<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Moulds')),
      floatingActionButton: FloatingActionButton(onPressed: ()=>_addOrEdit(), child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final m = items[i];
          final photoUrl = m['photoUrl'] as String?;
          return Card(child: ListTile(
            leading: photoUrl != null
              ? GestureDetector(
                  onTap: () => _showPhoto(photoUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                )
              : const CircleAvatar(
                  child: Icon(Icons.precision_manufacturing),
                ),
            title: Text('${m['number']} • ${m['name']}'),
            subtitle: Text('Mat: ${m['material']} • Cav: ${m['cavities']} • Cycle: ${m['cycleTime']}s • ${m['hotRunner']==true?'Hot runner':'Cold'}'),
            onTap: ()=>_addOrEdit(item: Map<String,dynamic>.from(m)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
              final mouldId = m['id'] as String;
              await box.delete(mouldId);
              await SyncService.deleteRemote('mouldsBox', mouldId);
              setState((){});
            }),
          ));
        }),
    );
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
