# Testing Push Notifications - Step by Step Guide

**Date:** November 7, 2024  
**Feature:** Firebase Cloud Messaging Push Notifications  
**Status:** Ready for Testing

---

## 🎯 Testing Overview

Since Flutter is not installed in this Gitpod environment, you'll need to test on your local machine or a device with Flutter installed.

---

## 📱 Method 1: Test on Physical Android Device (RECOMMENDED)

### Prerequisites
- Android device (Android 5.0+)
- USB cable or wireless debugging enabled
- Flutter SDK installed on your local machine
- Android Studio or VS Code with Flutter extension

### Step 1: Clone and Setup
```bash
# If not already cloned locally
git clone https://github.com/johanengel400-art/ProMould.git
cd ProMould

# Pull latest changes (includes push notifications)
git pull origin main

# Install dependencies
flutter pub get
```

### Step 2: Connect Your Device
```bash
# Enable USB debugging on your Android device:
# Settings → About Phone → Tap "Build Number" 7 times
# Settings → Developer Options → Enable "USB Debugging"

# Connect device via USB and verify
flutter devices

# You should see your device listed
```

### Step 3: Build and Run
```bash
# Run in debug mode (recommended for testing)
flutter run

# Or build APK and install manually
flutter build apk --debug
# APK will be at: build/app/outputs/flutter-apk/app-debug.apk
```

### Step 4: Test Notifications in App

1. **Launch the app** on your device

2. **Grant notification permission** when prompted
   - Tap "Allow" when permission dialog appears

3. **Navigate to notification settings:**
   - Open app → Settings → Notifications
   - You should see:
     - Notifications enabled status
     - Your FCM token (long string)
     - Alert type toggles

4. **Send test notification:**
   - Tap "Send Test Notification" button
   - Check notification tray
   - You should see: "Test Notification - This is a test from ProMould"

5. **Test topic subscriptions:**
   - Toggle different alert types on/off
   - Each toggle subscribes/unsubscribes from a topic

6. **Test notification tap:**
   - Tap on a notification
   - App should open/come to foreground

### Step 5: Test Background Notifications

1. **Put app in background:**
   - Press home button or switch to another app

2. **Send notification from Firebase Console** (see Method 2 below)

3. **Check notification tray:**
   - Notification should appear even when app is closed

4. **Tap notification:**
   - Should open the app

---

## 🔥 Method 2: Test from Firebase Console

### Step 1: Get Your FCM Token

1. **Run the app** on your device (see Method 1)

2. **Go to Settings → Notifications**

3. **Copy the FCM token** (long string displayed on screen)
   - Example: `dXYz123ABC...` (about 150+ characters)

### Step 2: Send Test Notification

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/
   - Select project: **promould-ed22a**

2. **Navigate to Cloud Messaging:**
   - Left sidebar → Engage → Cloud Messaging
   - Click "Send your first message" or "New campaign"

3. **Create notification:**
   - **Notification title:** "Test from Firebase"
   - **Notification text:** "This is a test notification"
   - Click "Next"

4. **Select target:**
   - Choose "FCM registration token"
   - Paste your FCM token from Step 1
   - Click "Next"

5. **Schedule (optional):**
   - Select "Now"
   - Click "Next"

6. **Additional options (optional):**
   - Skip or configure as needed
   - Click "Review"

7. **Send:**
   - Click "Publish"
   - Check your device for notification

### Step 3: Test Topic Notifications

1. **Subscribe to a topic in app:**
   - Open app → Settings → Notifications
   - Enable "Machine Alerts" (subscribes to `machine_alerts` topic)

2. **Send to topic from Firebase Console:**
   - Cloud Messaging → New campaign
   - Enter notification details
   - Target: Select "Topic"
   - Enter topic name: `machine_alerts`
   - Send

3. **Verify notification received** on device

---

## 🖥️ Method 3: Test with Command Line (cURL)

### Prerequisites
- FCM Server Key from Firebase Console
- FCM token from your device

### Step 1: Get Server Key

1. **Firebase Console:**
   - Go to: https://console.firebase.google.com/
   - Select project: **promould-ed22a**
   - Project Settings (gear icon) → Cloud Messaging
   - Copy "Server Key" (starts with `AAAA...`)

### Step 2: Send to Specific Device

```bash
# Replace YOUR_SERVER_KEY and YOUR_FCM_TOKEN
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test from cURL",
      "body": "This is a command line test"
    },
    "priority": "high"
  }'
```

### Step 3: Send to Topic

```bash
# Send to all users subscribed to "machine_alerts"
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/machine_alerts",
    "notification": {
      "title": "Machine Alert",
      "body": "Machine M-101 requires attention"
    },
    "data": {
      "type": "machine_breakdown",
      "machineId": "M-101"
    },
    "priority": "high"
  }'
```

### Step 4: Verify Response

Successful response:
```json
{
  "multicast_id": 123456789,
  "success": 1,
  "failure": 0,
  "canonical_ids": 0,
  "results": [
    {
      "message_id": "0:1234567890123456%abc123"
    }
  ]
}
```

---

## 🧪 Method 4: Test with Postman

### Step 1: Setup Postman

1. **Create new request:**
   - Method: POST
   - URL: `https://fcm.googleapis.com/fcm/send`

2. **Add headers:**
   - `Authorization`: `key=YOUR_SERVER_KEY`
   - `Content-Type`: `application/json`

3. **Add body (raw JSON):**
```json
{
  "to": "YOUR_FCM_TOKEN",
  "notification": {
    "title": "Test from Postman",
    "body": "This is a Postman test"
  },
  "priority": "high",
  "data": {
    "type": "test",
    "timestamp": "2024-11-07T17:00:00Z"
  }
}
```

4. **Send request** and check device

---

## ✅ Testing Checklist

### Basic Functionality
- [ ] App builds successfully
- [ ] Notification permission granted
- [ ] FCM token generated and displayed
- [ ] Test notification button works
- [ ] Notification appears in tray
- [ ] Notification tap opens app

### Foreground Notifications
- [ ] App is open and in foreground
- [ ] Send notification from Firebase Console
- [ ] Notification appears as local notification
- [ ] Notification sound plays
- [ ] Notification tap works

### Background Notifications
- [ ] App is in background (home screen)
- [ ] Send notification from Firebase Console
- [ ] Notification appears in system tray
- [ ] Notification sound plays
- [ ] Notification tap opens app

### Topic Subscriptions
- [ ] Subscribe to topic in app
- [ ] Send notification to topic
- [ ] Notification received
- [ ] Unsubscribe from topic
- [ ] Send notification to topic
- [ ] Notification NOT received

### Alert Types
- [ ] Enable "Job Alerts" → Subscribe to `job_alerts`
- [ ] Enable "Machine Alerts" → Subscribe to `machine_alerts`
- [ ] Enable "Quality Alerts" → Subscribe to `quality_alerts`
- [ ] Enable "Maintenance Alerts" → Subscribe to `maintenance_alerts`
- [ ] Enable "Mould Change Alerts" → Subscribe to `mould_change_alerts`

### Data Payload
- [ ] Send notification with custom data
- [ ] Verify data received in app
- [ ] Test navigation based on data

---

## 🐛 Troubleshooting

### Notification Not Received

**Check 1: Permission**
```dart
// In app, check permission status
Settings → Notifications → Check if enabled
```

**Check 2: FCM Token**
```dart
// Verify token is generated
Settings → Notifications → Check if token is displayed
```

**Check 3: Network**
```bash
# Ensure device has internet connection
# FCM requires active internet
```

**Check 4: Firebase Console**
```
# Verify notification was sent successfully
# Check for error messages in Firebase Console
```

### App Crashes on Notification

**Check logs:**
```bash
# View Android logs
flutter logs

# Or use adb
adb logcat | grep -i flutter
```

### Token Not Generated

**Verify google-services.json:**
```bash
# Check file exists
ls -la android/app/google-services.json

# Verify package name matches
grep "package_name" android/app/google-services.json
# Should show: "package_name": "com.promould.app"
```

### Notification Not Showing in Foreground

**Check PushNotificationService:**
```dart
// Verify local notifications are initialized
// Check logs for initialization errors
```

---

## 📊 Expected Results

### Test Notification from App
```
✅ Notification appears in tray
✅ Title: "Test Notification"
✅ Body: "This is a test from ProMould"
✅ Icon: App icon
✅ Sound: Default notification sound
✅ Tap: Opens app
```

### Notification from Firebase Console
```
✅ Notification appears in tray
✅ Title: Your custom title
✅ Body: Your custom message
✅ Delivered within 1-2 seconds
✅ Works in foreground and background
```

### Topic Notification
```
✅ Only users subscribed to topic receive it
✅ Unsubscribed users don't receive it
✅ Multiple users can receive same notification
```

---

## 🔗 Quick Links

- **Firebase Console:** https://console.firebase.google.com/project/promould-ed22a
- **Cloud Messaging:** https://console.firebase.google.com/project/promould-ed22a/notification
- **Setup Guide:** `PUSH_NOTIFICATIONS_GUIDE.md`
- **Configuration:** `FIREBASE_SETUP_COMPLETE.md`

---

## 📝 Testing Notes

### Important
1. **Physical device recommended** - Emulators may have limited FCM support
2. **Internet required** - FCM needs active internet connection
3. **Google Play Services** - Required on Android device
4. **First launch** - Permission must be granted on first launch
5. **Background restrictions** - Some devices may restrict background notifications

### Tips
- Test on multiple devices if possible
- Test with different Android versions
- Test with app in different states (foreground, background, killed)
- Test with different notification priorities
- Test with and without data payload

---

## 🎓 Next Steps After Testing

### If Tests Pass ✅
1. Implement backend API for sending notifications
2. Store FCM tokens in Firestore
3. Create notification scheduling system
4. Add notification analytics
5. Test on iOS (requires separate setup)

### If Tests Fail ❌
1. Check error logs: `flutter logs`
2. Verify Firebase configuration
3. Check package name matches
4. Verify google-services.json is correct
5. Ensure Google Play Services installed on device

---

**Status:** Ready for Testing  
**Platform:** Android  
**Requirements:** Physical device with Flutter installed locally

---

*Document created: November 7, 2024*  
*Push notifications testing guide*
