# Firebase Push Notifications Setup Guide

This guide explains how to set up and use Firebase Cloud Messaging (FCM) for push notifications in the Skillzaar app.

## Features Implemented

✅ **Firebase Cloud Messaging Integration**
- FCM token generation and management
- Background and foreground message handling
- Local notifications display

✅ **Cross-Platform Support**
- Android notification configuration
- iOS notification configuration
- Works on both platforms

✅ **Job Notification System**
- Automatic notifications when jobs are posted
- Notifications sent to all skilled workers
- Rich notification content with job details

✅ **Permission Handling**
- Automatic permission requests
- Graceful handling of denied permissions

## Files Added/Modified

### New Files Created:
- `lib/core/services/notification_service.dart` - Core notification service
- `lib/presentation/providers/notification_provider.dart` - State management
- `lib/presentation/widgets/notification_initializer.dart` - App initialization
- `lib/presentation/widgets/provider_connector.dart` - Provider connections
- `lib/presentation/screens/test_notification_screen.dart` - Testing interface

### Modified Files:
- `pubspec.yaml` - Added FCM dependencies
- `lib/main.dart` - Added notification provider and initializer
- `lib/presentation/providers/job_provider.dart` - Integrated notification sending
- `lib/presentation/routes/app_routes.dart` - Added test screen route
- `android/app/src/main/AndroidManifest.xml` - Added notification permissions
- `ios/Runner/Info.plist` - Added iOS notification configuration

## Dependencies Added

```yaml
dependencies:
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
```

## Android Configuration

### Permissions Added:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### Notification Channel:
- Channel ID: `job_notifications`
- Channel Name: `Job Notifications`
- Importance: High
- Sound: Enabled

## iOS Configuration

### Background Modes:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## How It Works

### 1. Initialization
- App starts and initializes Firebase
- Notification service requests permissions
- FCM token is generated and saved to Firestore
- User subscribes to 'job_notifications' topic

### 2. Job Posting Flow
- User posts a job through the app
- Job data is saved to Firestore
- Notification service sends notification to all skilled workers
- Each worker receives a push notification

### 3. Notification Handling
- **Foreground**: Shows local notification
- **Background**: Handles via background message handler
- **App Closed**: Notification appears in system tray

## Testing

### Test Screen
Navigate to `/test-notifications` to access the test interface:
- View notification status
- Send test notifications
- Refresh FCM token
- Unsubscribe from notifications

### Manual Testing Steps:
1. Install the app on a physical device
2. Grant notification permissions
3. Navigate to test screen
4. Tap "Send Test Job Notification"
5. Check if notification appears

## Usage in Code

### Sending Notifications
```dart
// Get notification provider
final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

// Send job notification
await notificationProvider.sendJobNotification(
  jobTitle: 'Plumber Needed',
  jobDescription: 'Fix leaking pipe',
  jobId: 'job_123',
  location: 'Karachi',
  budget: 5000.0,
);
```

### Checking Status
```dart
Consumer<NotificationProvider>(
  builder: (context, provider, child) {
    return Text('Initialized: ${provider.isInitialized}');
  },
)
```

## Firebase Console Setup

### 1. Enable Cloud Messaging
- Go to Firebase Console
- Select your project
- Navigate to Cloud Messaging
- Enable the service

### 2. Configure Server Key
- Go to Project Settings
- Select Cloud Messaging tab
- Copy the Server Key
- Use this key in your backend to send notifications

## Backend Integration

To send notifications from your backend server, use the FCM REST API:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/job_notifications",
    "notification": {
      "title": "New Job Posted",
      "body": "A new job has been posted in your area"
    },
    "data": {
      "jobId": "job_123",
      "type": "job_posting"
    }
  }'
```

## Troubleshooting

### Common Issues:

1. **Notifications not appearing**
   - Check if permissions are granted
   - Verify FCM token is generated
   - Check device notification settings

2. **iOS notifications not working**
   - Ensure APNs certificates are configured
   - Check bundle ID matches Firebase project
   - Verify background modes are enabled

3. **Android notifications not working**
   - Check if Google Play Services is installed
   - Verify notification channel is created
   - Check if app is not battery optimized

### Debug Steps:
1. Check console logs for FCM token
2. Verify token is saved to Firestore
3. Test with Firebase Console messaging
4. Check device notification settings

## Security Considerations

- FCM tokens are stored in Firestore with user authentication
- Only authenticated users can send notifications
- Server key should be kept secure
- Consider implementing rate limiting

## Future Enhancements

- [ ] Rich notification media (images)
- [ ] Notification categories and actions
- [ ] Scheduled notifications
- [ ] Notification analytics
- [ ] Custom notification sounds
- [ ] Notification preferences per user

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Firebase documentation
3. Check Flutter FCM plugin documentation
4. Contact development team
