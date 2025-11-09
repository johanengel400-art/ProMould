// lib/screens/notification_settings_screen.dart
// Notification settings and preferences

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/push_notification_service.dart';
import '../services/log_service.dart';
import '../theme/dark_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late Box _settingsBox;
  bool _notificationsEnabled = false;
  String? _fcmToken;
  
  // Topic subscriptions
  bool _jobAlerts = true;
  bool _machineAlerts = true;
  bool _qualityAlerts = true;
  bool _maintenanceAlerts = true;
  bool _mouldChangeAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox('settingsBox');
    
    final enabled = await PushNotificationService.areNotificationsEnabled();
    final token = PushNotificationService.fcmToken;
    
    setState(() {
      _notificationsEnabled = enabled;
      _fcmToken = token;
      
      // Load topic subscriptions
      _jobAlerts = _settingsBox.get('notify_jobs', defaultValue: true);
      _machineAlerts = _settingsBox.get('notify_machines', defaultValue: true);
      _qualityAlerts = _settingsBox.get('notify_quality', defaultValue: true);
      _maintenanceAlerts = _settingsBox.get('notify_maintenance', defaultValue: true);
      _mouldChangeAlerts = _settingsBox.get('notify_mould_changes', defaultValue: true);
    });
  }

  Future<void> _toggleTopic(String topic, bool subscribe) async {
    if (subscribe) {
      await PushNotificationService.subscribeToTopic(topic);
    } else {
      await PushNotificationService.unsubscribeFromTopic(topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                        color: _notificationsEnabled ? AppTheme.accent : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _notificationsEnabled ? 'Notifications Enabled' : 'Notifications Disabled',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _notificationsEnabled
                                  ? 'You will receive push notifications'
                                  : 'Enable notifications in system settings',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_fcmToken != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Device Token',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fcmToken!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Alert Types
          const Text(
            'Alert Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose which types of alerts you want to receive',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Job Alerts
          Card(
            child: SwitchListTile(
              title: const Text('Job Alerts'),
              subtitle: const Text('Job completion, start, and progress updates'),
              value: _jobAlerts,
              onChanged: _notificationsEnabled ? (value) async {
                setState(() => _jobAlerts = value);
                await _settingsBox.put('notify_jobs', value);
                await _toggleTopic('job_alerts', value);
              } : null,
              secondary: const Icon(Icons.work_outline),
            ),
          ),
          
          // Machine Alerts
          Card(
            child: SwitchListTile(
              title: const Text('Machine Alerts'),
              subtitle: const Text('Breakdowns, status changes, and issues'),
              value: _machineAlerts,
              onChanged: _notificationsEnabled ? (value) async {
                setState(() => _machineAlerts = value);
                await _settingsBox.put('notify_machines', value);
                await _toggleTopic('machine_alerts', value);
              } : null,
              secondary: const Icon(Icons.precision_manufacturing),
            ),
          ),
          
          // Quality Alerts
          Card(
            child: SwitchListTile(
              title: const Text('Quality Alerts'),
              subtitle: const Text('High scrap rates and quality issues'),
              value: _qualityAlerts,
              onChanged: _notificationsEnabled ? (value) async {
                setState(() => _qualityAlerts = value);
                await _settingsBox.put('notify_quality', value);
                await _toggleTopic('quality_alerts', value);
              } : null,
              secondary: const Icon(Icons.verified_outlined),
            ),
          ),
          
          // Maintenance Alerts
          Card(
            child: SwitchListTile(
              title: const Text('Maintenance Alerts'),
              subtitle: const Text('Maintenance due and service reminders'),
              value: _maintenanceAlerts,
              onChanged: _notificationsEnabled ? (value) async {
                setState(() => _maintenanceAlerts = value);
                await _settingsBox.put('notify_maintenance', value);
                await _toggleTopic('maintenance_alerts', value);
              } : null,
              secondary: const Icon(Icons.build_outlined),
            ),
          ),
          
          // Mould Change Alerts
          Card(
            child: SwitchListTile(
              title: const Text('Mould Change Alerts'),
              subtitle: const Text('Scheduled and overdue mould changes'),
              value: _mouldChangeAlerts,
              onChanged: _notificationsEnabled ? (value) async {
                setState(() => _mouldChangeAlerts = value);
                await _settingsBox.put('notify_mould_changes', value);
                await _toggleTopic('mould_change_alerts', value);
              } : null,
              secondary: const Icon(Icons.swap_horiz),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Test Notification Button
          if (_notificationsEnabled)
            ElevatedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
            ),
          
          const SizedBox(height: 16),
          
          // Info Card
          Card(
            color: AppTheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'About Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Push notifications help you stay informed about important events in your factory. '
                    'You can customize which alerts you receive and manage your preferences at any time.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    LogService.info('Sending test notification');
    
    // In production, this would trigger a backend call to send a real push notification
    await PushNotificationService.sendToTopic(
      'test',
      title: 'Test Notification',
      body: 'This is a test notification from ProMould',
      data: {'type': 'test'},
    );
    
    // Show confirmation after sending
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent! Check your notification tray.'),
        backgroundColor: AppTheme.accent,
      ),
    );
  }
}
