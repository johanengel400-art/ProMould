import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/photo_service.dart';

class IssuesScreen extends StatefulWidget{
  final String username; final int level;
  const IssuesScreen({super.key, required this.username, required this.level});
  @override State<IssuesScreen> createState()=>_IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>{
  final uuid=const Uuid();
  final descCtrl=TextEditingController();
  String? imageUrl;

  void _addIssue() async {
    final issuesBox = Hive.box('issuesBox');
    final id = uuid.v4();
    issuesBox.add({
      'id': id,
      'description': descCtrl.text.trim(),
      'photoUrl': imageUrl ?? '',
      'reportedBy': widget.username,
      'timestamp': DateTime.now(),
    });
    descCtrl.clear(); imageUrl=null; setState((){});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue logged.')));
  }

  Future<void> _takePhoto() async {
    final id = uuid.v4();
    final url = await PhotoService.captureAndUpload(id);
    if(url!=null){ setState(()=>imageUrl=url); }
  }

  Future<void> _pickPhoto() async {
    final id = uuid.v4();
    final url = await PhotoService.chooseAndUpload(id);
    if(url!=null){ setState(()=>imageUrl=url); }
  }

  @override Widget build(BuildContext context){
    final issuesBox = Hive.box('issuesBox');
    return Scaffold(
      appBar: AppBar(title: const Text('Issues & Defects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:_addIssue, label: const Text('Save'), icon: const Icon(Icons.save)),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(16), child: Column(children:[
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText:'Description')),
          const SizedBox(height: 8),
          Row(children:[
            ElevatedButton.icon(onPressed:_takePhoto, icon: const Icon(Icons.photo_camera), label: const Text('Camera')),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed:_pickPhoto, icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
          ]),
          if(imageUrl!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text('Attached: $imageUrl', maxLines: 1, overflow: TextOverflow.ellipsis)),
        ])),
        const Divider(height: 1),
        Expanded(child: ValueListenableBuilder(
          valueListenable: issuesBox.listenable(),
          builder: (_, __, ___){
            final items = issuesBox.values.cast<Map>().toList().reversed.toList();
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (_,i){
                final it = items[i];
                return ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: Text('${it['description']}'),
                  subtitle: Text('By ${it['reportedBy']} • ${it['timestamp']}'),
                  trailing: it['photoUrl']!=null && (it['photoUrl'] as String).isNotEmpty
                    ? const Icon(Icons.image, color: Colors.white70)
                    : const SizedBox.shrink(),
                );
              });
          },
        )),
      ]),
    );
  }
}
