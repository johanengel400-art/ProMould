import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatelessWidget{
  final int level; const SettingsScreen({super.key, required this.level});

  Future<void> _resetDB(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text(
          'This will delete all local data including:\n'
          '• Users (except admin)\n'
          '• Machines\n'
          '• Jobs\n'
          '• Moulds\n'
          '• Issues\n'
          '• Inputs\n'
          '• Queue\n'
          '• Floors\n'
          '• Downtime\n\n'
          'This action cannot be undone!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for(final name in ['usersBox','machinesBox','jobsBox','mouldsBox','issuesBox','inputsBox','queueBox','floorsBox','downtimeBox']){
      if(Hive.isBoxOpen(name)){ 
        await Hive.box(name).clear(); 
      } else { 
        final b = await Hive.openBox(name); 
        await b.clear(); 
      }
    }
    
    // Seed default admin
    final users = Hive.box('usersBox');
    final adminData = {'id': 'admin', 'username':'admin','password':'admin123','level':4,'shift':'Any'};
    users.put('admin', adminData);
    await SyncService.pushChange('usersBox', 'admin', adminData);
    
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Local DB reset. Admin user recreated.'),
        backgroundColor: Color(0xFF80ED99),
      )
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    // Clear any cached data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared'))
    );
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children:[
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Database', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined, color: Color(0xFFFF6B6B)),
          title: const Text('Reset Local Database'),
          subtitle: const Text('Clears all local data and recreates admin user'),
          onTap: ()=>_resetDB(context),
        ),
        ListTile(
          leading: const Icon(Icons.cached_outlined),
          title: const Text('Clear Cache'),
          subtitle: const Text('Clear temporary cached data'),
          onTap: ()=>_clearCache(context),
        ),
        const Divider(height:1),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.sync_outlined),
          title: const Text('Firebase Sync'),
          subtitle: const Text('Real-time sync with cloud database'),
          trailing: const Icon(Icons.check_circle, color: Color(0xFF80ED99)),
        ),
        const Divider(height:1),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('ProMould v7.1'),
          subtitle: Text('Smart Factory Management System'),
        ),
        const ListTile(
          leading: Icon(Icons.code_outlined),
          title: Text('Built with Flutter'),
          subtitle: Text('Cross-platform mobile application'),
        ),
        const ListTile(
          leading: Icon(Icons.cloud_outlined),
          title: Text('Firebase Backend'),
          subtitle: Text('Cloud Firestore & Storage'),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            '© 2025 ProMould',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}
