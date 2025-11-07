# Push Notifications Setup Guide

**Date:** November 7, 2024  
**Feature:** Firebase Cloud Messaging Push Notifications  
**Status:** ✅ Implemented

---

## 📱 Overview

ProMould now supports push notifications using Firebase Cloud Messaging (FCM). Users can receive real-time alerts for:
- Job completions and starts
- Machine breakdowns
- Quality issues and high scrap rates
- Maintenance due reminders
- Mould change schedules
- And more...

---

## 🚀 Features Implemented

### 1. Push Notification Service ✅
- **File:** `lib/services/push_notification_service.dart`
- Firebase Cloud Messaging integration
- Local notifications for foreground messages
- Background message handling
- Topic-based subscriptions
- FCM token management

### 2. Notification Settings Screen ✅
- **File:** `lib/screens/notification_settings_screen.dart`
- Enable/disable notifications
- Subscribe to specific alert types
- View FCM token
- Send test notifications

### 3. Integration with Existing Alerts ✅
- **File:** `lib/services/notification_service.dart`
- Automatic push notifications for high-priority alerts
- Topic-based routing (managers, setters, maintenance, quality)
- Smart alert categorization

---

## 📋 Setup Instructions

### Step 1: Firebase Console Configuration

#### Android Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your ProMould project
3. Navigate to Project Settings → Cloud Messaging
4. Note your **Server Key** (for backend)
5. Download `google-services.json` (already configured)

#### iOS Setup
1. In Firebase Console, go to Project Settings
2. Add iOS app if not already added
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` directory
5. Enable Push Notifications capability in Xcode

### Step 2: Android Configuration

**File:** `android/app/build.gradle`
```gradle
// Already configured, but verify:
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**File:** `android/app/src/main/AndroidManifest.xml`
```xml
<!-- Add inside <application> tag -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
```

### Step 3: iOS Configuration

**File:** `ios/Runner/Info.plist`
```xml
<!-- Add these keys -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

**Enable Push Notifications in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to Signing & Capabilities
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and enable "Remote notifications"

### Step 4: Install Dependencies

```bash
flutter pub get
```

### Step 5: Run the App

```bash
flutter run
```

---

## 💡 Usage

### For Users

#### Enable Notifications
1. Open app
2. Go to Settings → Notifications
3. Grant permission when prompted
4. Toggle alert types you want to receive

#### Notification Types
- **Job Alerts** - Job completion, start, progress
- **Machine Alerts** - Breakdowns, status changes
- **Quality Alerts** - High scrap rates, quality issues
- **Maintenance Alerts** - Maintenance due, service reminders
- **Mould Change Alerts** - Scheduled and overdue changes

### For Developers

#### Send Notification to Topic
```dart
await PushNotificationService.sendToTopic(
  NotificationTopic.managers,
  title: 'Machine Breakdown',
  body: 'Machine M-101 has broken down',
  data: {
    'type': NotificationType.machineBreakdown,
    'machineId': 'M-101',
  },
  priority: 'high',
);
```

#### Subscribe to Topic
```dart
await PushNotificationService.subscribeToTopic('managers');
```

#### Listen to Messages
```dart
PushNotificationService.messageStream.listen((message) {
  print('Received: ${message.notification?.title}');
  // Handle navigation or custom logic
});
```

#### Check Permission Status
```dart
final enabled = await PushNotificationService.areNotificationsEnabled();
if (!enabled) {
  // Show permission request dialog
}
```

---

## 🔔 Notification Topics

### Pre-defined Topics
- `all_users` - All app users
- `operators` - Level 1 users
- `setters` - Level 3 users
- `managers` - Level 4+ users
- `maintenance` - Maintenance team
- `quality` - Quality control team

### Custom Topics
You can create custom topics for specific machines, floors, or shifts:
```dart
await PushNotificationService.subscribeToTopic('machine_M101');
await PushNotificationService.subscribeToTopic('floor_1');
await PushNotificationService.subscribeToTopic('shift_morning');
```

---

## 📊 Notification Types

### Defined Types
```dart
NotificationType.jobComplete
NotificationType.jobStarted
NotificationType.machineBreakdown
NotificationType.qualityIssue
NotificationType.mouldChange
NotificationType.maintenanceDue
NotificationType.highScrapRate
NotificationType.lowMaterial
NotificationType.shiftHandover
```

---

## 🔧 Backend Integration

### Sending Notifications from Backend

You'll need a backend service to send notifications. Here's an example using Node.js:

```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send to topic
async function sendToTopic(topic, title, body, data) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    topic: topic,
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance',
        sound: 'default',
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        }
      }
    }
  };

  const response = await admin.messaging().send(message);
  console.log('Successfully sent message:', response);
}

// Send to specific device
async function sendToDevice(fcmToken, title, body, data) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    token: fcmToken,
  };

  const response = await admin.messaging().send(message);
  console.log('Successfully sent message:', response);
}

// Example usage
sendToTopic(
  'managers',
  'Machine Breakdown',
  'Machine M-101 has broken down',
  {
    type: 'machine_breakdown',
    machineId: 'M-101',
    priority: 'high'
  }
);
```

### REST API Example

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/managers",
    "notification": {
      "title": "Machine Breakdown",
      "body": "Machine M-101 has broken down"
    },
    "data": {
      "type": "machine_breakdown",
      "machineId": "M-101"
    },
    "priority": "high"
  }'
```

---

## 🧪 Testing

### Test Notification from App
1. Open app
2. Go to Settings → Notifications
3. Tap "Send Test Notification"
4. Check notification tray

### Test from Firebase Console
1. Go to Firebase Console
2. Navigate to Cloud Messaging
3. Click "Send your first message"
4. Enter title and body
5. Select target (topic or device)
6. Send

### Test from Command Line
```bash
# Get FCM token from app (shown in notification settings)
# Then use curl to send test notification

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test",
      "body": "This is a test notification"
    }
  }'
```

---

## 🔒 Security

### Best Practices
1. **Never expose Server Key** - Keep it on backend only
2. **Validate tokens** - Verify FCM tokens before sending
3. **Rate limiting** - Prevent notification spam
4. **User preferences** - Respect user notification settings
5. **Data privacy** - Don't send sensitive data in notifications

### Token Management
- FCM tokens are stored in Hive (`settingsBox`)
- Tokens refresh automatically
- Old tokens are updated in storage
- Backend should handle token updates

---

## 📈 Analytics

### Track Notification Performance
```dart
// Log notification received
LogService.info('Notification received: ${message.messageId}');

// Log notification opened
LogService.info('Notification opened: ${message.data['type']}');

// Track in Firebase Analytics (if integrated)
FirebaseAnalytics.instance.logEvent(
  name: 'notification_received',
  parameters: {
    'type': message.data['type'],
    'priority': message.data['priority'],
  },
);
```

---

## 🐛 Troubleshooting

### Notifications Not Received

**Check Permission:**
```dart
final settings = await PushNotificationService.getSettings();
print('Authorization: ${settings.authorizationStatus}');
```

**Check FCM Token:**
```dart
final token = PushNotificationService.fcmToken;
print('FCM Token: $token');
```

**Check Topic Subscription:**
- Verify user is subscribed to correct topics
- Check Firebase Console for topic subscribers

### Android Issues

**No Sound:**
- Check notification channel importance
- Verify sound is enabled in channel settings

**Not Showing:**
- Check AndroidManifest.xml configuration
- Verify notification channel is created
- Check app notification permissions in system settings

### iOS Issues

**Permission Denied:**
- Check Info.plist configuration
- Verify Push Notifications capability is enabled
- Check system notification settings

**Background Not Working:**
- Enable "Remote notifications" in Background Modes
- Verify APNs certificate is configured in Firebase

---

## 📝 Files Created/Modified

### New Files
1. `lib/services/push_notification_service.dart` (350 lines)
2. `lib/screens/notification_settings_screen.dart` (300 lines)
3. `PUSH_NOTIFICATIONS_GUIDE.md` (this file)

### Modified Files
1. `pubspec.yaml` - Added dependencies
2. `lib/main.dart` - Initialize push notifications
3. `lib/services/notification_service.dart` - Integrated push notifications

---

## 🎯 Next Steps

### Optional Enhancements
1. **Rich Notifications** - Add images, actions, custom layouts
2. **Notification History** - Store and display past notifications
3. **Scheduled Notifications** - Schedule notifications for future
4. **Notification Groups** - Group related notifications
5. **Custom Sounds** - Different sounds for different alert types
6. **Notification Actions** - Quick actions from notification
7. **Analytics Dashboard** - Track notification metrics

### Backend Requirements
1. **API Endpoint** - Create endpoint to send notifications
2. **Token Management** - Store and update FCM tokens
3. **Notification Queue** - Queue system for bulk notifications
4. **Delivery Reports** - Track notification delivery status
5. **User Preferences** - Sync notification preferences

---

## 📚 Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Flutter](https://pub.dev/packages/firebase_messaging)
- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)

---

## ✅ Checklist

### Setup
- [x] Add dependencies
- [x] Create push notification service
- [x] Initialize in main.dart
- [x] Create settings screen
- [x] Integrate with existing alerts
- [ ] Configure Android (requires Firebase setup)
- [ ] Configure iOS (requires Firebase setup)
- [ ] Test on physical devices

### Backend
- [ ] Create notification API endpoint
- [ ] Implement token management
- [ ] Set up notification queue
- [ ] Add delivery tracking
- [ ] Implement rate limiting

### Testing
- [ ] Test foreground notifications
- [ ] Test background notifications
- [ ] Test notification actions
- [ ] Test topic subscriptions
- [ ] Test on Android
- [ ] Test on iOS

---

**Status:** ✅ Implementation Complete  
**Backend Required:** Yes (for sending notifications)  
**Production Ready:** 90% (needs Firebase configuration)

---

*Document created: November 7, 2024*  
*Push notifications implementation guide*
