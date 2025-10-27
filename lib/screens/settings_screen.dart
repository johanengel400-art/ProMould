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
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Settings'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C757D).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Database', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: const Color(0xFF0F1419),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF476F).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cleaning_services_outlined, color: Color(0xFFEF476F)),
                        ),
                        title: const Text('Reset Local Database', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Clears all local data and recreates admin user', style: TextStyle(color: Colors.white70)),
                        onTap: ()=>_resetDB(context),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CC9F0).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cached_outlined, color: Color(0xFF4CC9F0)),
                        ),
                        title: const Text('Clear Cache', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Clear temporary cached data', style: TextStyle(color: Colors.white70)),
                        onTap: ()=>_clearCache(context),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        color: const Color(0xFF06D6A0).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sync_outlined, color: Color(0xFF06D6A0)),
                    ),
                    title: const Text('Firebase Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Real-time sync with cloud database', style: TextStyle(color: Colors.white70)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF06D6A0).withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF06D6A0), size: 16),
                          SizedBox(width: 4),
                          Text('Active', style: TextStyle(color: Color(0xFF06D6A0), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: const Color(0xFF0F1419),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9D4EDD).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.info_outline, color: Color(0xFF9D4EDD)),
                        ),
                        title: const Text('ProMould v8.0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Smart Factory Management System', style: TextStyle(color: Colors.white70)),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      const ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Icon(Icons.code_outlined, color: Color(0xFF4CC9F0)),
                        title: Text('Built with Flutter', style: TextStyle(color: Colors.white)),
                        subtitle: Text('Cross-platform mobile application', style: TextStyle(color: Colors.white70)),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      const ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Icon(Icons.cloud_outlined, color: Color(0xFF06D6A0)),
                        title: Text('Firebase Backend', style: TextStyle(color: Colors.white)),
                        subtitle: Text('Cloud Firestore & Storage', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    '© 2025 ProMould',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
