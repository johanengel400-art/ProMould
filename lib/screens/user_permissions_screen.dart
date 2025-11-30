import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/user_permissions.dart';
import '../services/sync_service.dart';
import '../services/log_service.dart';

class UserPermissionsScreen extends StatefulWidget {
  const UserPermissionsScreen({super.key});

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  String? _selectedUsername;
  Map<String, bool> _permissions = {};

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('User Permissions'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: isPortrait
          ? Column(
              children: [
                // User list (top half in portrait)
                Expanded(
                  flex: 1,
                  child: _buildUserList(),
                ),
                const Divider(height: 1),
                // Permissions editor (bottom half in portrait)
                Expanded(
                  flex: 2,
                  child: _selectedUsername == null
                      ? const Center(
                          child: Text(
                            'Select a user to edit permissions',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : _buildPermissionsEditor(),
                ),
              ],
            )
          : Row(
              children: [
                // User list (left side in landscape)
                SizedBox(
                  width: 250,
                  child: _buildUserList(),
                ),
                const VerticalDivider(width: 1),
                // Permissions editor (right side in landscape)
                Expanded(
                  child: _selectedUsername == null
                      ? const Center(
                          child: Text(
                            'Select a user to edit permissions',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : _buildPermissionsEditor(),
                ),
              ],
            ),
    );
  }

  Widget _buildUserList() {
    final usersBox = Hive.box('usersBox');
    final users = usersBox.values.cast<Map>().toList();

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final username = user['username'] as String;
        final level = user['level'] as int;
        final isSelected = username == _selectedUsername;

        return ListTile(
          selected: isSelected,
          selectedTileColor: Colors.blue.withOpacity(0.2),
          title: Text(
            username,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Level $level',
            style: const TextStyle(color: Colors.white70),
          ),
          onTap: () => _selectUser(username, user),
        );
      },
    );
  }

  void _selectUser(String username, Map user) {
    setState(() {
      _selectedUsername = username;
      final level = user['level'] as int;

      // Start with defaults for this level
      _permissions = UserPermissions.getDefaultPermissions(level);
      
      // Merge in any custom permissions (overriding defaults)
      if (user['permissions'] != null) {
        final customPermissions = Map<String, bool>.from(user['permissions'] as Map);
        _permissions.addAll(customPermissions);
      }
      
      LogService.debug('Loaded permissions for $username (level $level): $_permissions');
    });
  }

  Widget _buildPermissionsEditor() {
    final allPermissions = UserPermissions.getAllPermissions();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1F2E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Permissions for $_selectedUsername',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: const Text('Reset to Defaults'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Permissions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allPermissions.length,
            itemBuilder: (context, index) {
              final permission = allPermissions[index];
              final pageName = UserPermissions.getPageName(permission);
              final isEnabled = _permissions[permission] ?? false;

              return Card(
                color: const Color(0xFF1A1F2E),
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  title: Text(
                    pageName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    permission,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _permissions[permission] = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    final usersBox = Hive.box('usersBox');
    final user = usersBox.get(_selectedUsername) as Map?;
    if (user == null) return;

    final level = user['level'] as int;
    setState(() {
      _permissions = UserPermissions.getDefaultPermissions(level);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default permissions')),
    );
  }

  Future<void> _savePermissions() async {
    if (_selectedUsername == null) return;

    try {
      final usersBox = Hive.box('usersBox');
      final user =
          Map<String, dynamic>.from(usersBox.get(_selectedUsername) as Map);

      // Save the complete permission set
      user['permissions'] = Map<String, bool>.from(_permissions);

      await usersBox.put(_selectedUsername, user);
      await SyncService.pushChange('usersBox', _selectedUsername!, user);

      LogService.info('Updated permissions for $_selectedUsername: $_permissions');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LogService.error('Failed to save permissions', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
