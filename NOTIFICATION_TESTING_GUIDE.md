# Notification Testing Guide

## 🎯 Testing Job Assignment Notifications

This guide will help you test that skilled workers receive notifications when jobs are assigned from the admin panel, regardless of whether the app is running or not.

## 📱 Test Scenarios

### Scenario 1: App is Running (Foreground)
1. **Open the app** on the skilled worker's device
2. **Admin assigns a job** from the web panel
3. **Expected Result**: 
   - Notification appears in the notification tray
   - App shows the notification immediately
   - Tapping notification navigates to assigned job detail screen

### Scenario 2: App is in Background
1. **Open the app** on the skilled worker's device
2. **Minimize the app** (don't close it completely)
3. **Admin assigns a job** from the web panel
4. **Expected Result**:
   - Notification appears in the notification tray
   - Tapping notification brings app to foreground
   - App navigates to assigned job detail screen

### Scenario 3: App is Completely Closed
1. **Close the app completely** on the skilled worker's device
2. **Admin assigns a job** from the web panel
3. **Expected Result**:
   - Notification appears in the notification tray
   - Tapping notification opens the app
   - App navigates to assigned job detail screen

## 🔧 Setup Requirements

### 1. FCM Token Storage
Ensure the skilled worker's FCM token is saved in the database:

```javascript
// In SkilledWorkers collection
{
  "skilledWorkerId": "worker_123",
  "fcmToken": "fcm_token_here",
  "lastTokenUpdate": "timestamp"
}
```

### 2. Cloud Functions Deployed
Make sure the Cloud Functions are deployed:

```bash
cd functions
npm install
firebase deploy --only functions
```

### 3. Notification Permissions
The app should request notification permissions on first launch.

## 🧪 Step-by-Step Testing

### Step 1: Prepare Test Environment

1. **Install the app** on a test device
2. **Login as a skilled worker**
3. **Check FCM token** is saved in Firestore:
   ```javascript
   // Check in Firebase Console
   SkilledWorkers -> [worker_id] -> fcmToken field
   ```

### Step 2: Test Foreground Notifications

1. **Keep app open** on skilled worker device
2. **Open admin panel** in browser
3. **Assign a job** to the skilled worker
4. **Check notification** appears immediately
5. **Tap notification** and verify navigation

### Step 3: Test Background Notifications

1. **Minimize the app** (don't close)
2. **Assign another job** from admin panel
3. **Check notification** appears in system tray
4. **Tap notification** and verify app opens and navigates

### Step 4: Test Closed App Notifications

1. **Force close the app** completely
2. **Assign another job** from admin panel
3. **Check notification** appears in system tray
4. **Tap notification** and verify app opens and navigates

## 🔍 Debugging

### Check Cloud Functions Logs

1. Go to Firebase Console
2. Navigate to Functions
3. Click on `onJobAssigned` function
4. Check logs for execution details

### Check FCM Token

1. Go to Firebase Console
2. Navigate to Firestore
3. Check `SkilledWorkers` collection
4. Verify `fcmToken` field exists and is valid

### Check Notification Delivery

1. Go to Firebase Console
2. Navigate to Cloud Messaging
3. Check delivery reports
4. Verify notifications are being sent

## 🐛 Common Issues & Solutions

### Issue 1: No Notifications Received

**Possible Causes:**
- FCM token not saved
- Cloud Functions not deployed
- Notification permissions not granted
- Device not connected to internet

**Solutions:**
1. Check FCM token in database
2. Redeploy Cloud Functions
3. Grant notification permissions
4. Check internet connection

### Issue 2: Notifications Received but No Navigation

**Possible Causes:**
- Navigator key not initialized
- Route not found
- Notification data format incorrect

**Solutions:**
1. Check navigator key initialization
2. Verify route names
3. Check notification data format

### Issue 3: App Crashes on Notification Tap

**Possible Causes:**
- Invalid route arguments
- Missing dependencies
- Context issues

**Solutions:**
1. Check route argument format
2. Verify all imports
3. Check context availability

## 📊 Expected Notification Data

When a job is assigned, the notification should contain:

```javascript
{
  "notification": {
    "title": "🎉 Job Assigned!",
    "body": "You have been assigned to: [Job Title]"
  },
  "data": {
    "type": "job_assigned",
    "assignedJobId": "assignment_123",
    "jobId": "job_456",
    "userType": "skilled_worker",
    "timestamp": "1234567890"
  }
}
```

## 🚀 Production Checklist

- [ ] Cloud Functions deployed
- [ ] FCM tokens being saved
- [ ] Notification permissions granted
- [ ] Background message handler working
- [ ] Navigation working for all scenarios
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Testing completed

## 📱 Device-Specific Notes

### Android
- Requires `POST_NOTIFICATIONS` permission (API 33+)
- Notifications work in all app states
- Background processing works automatically

### iOS
- Requires notification permissions
- Background app refresh should be enabled
- Notifications work in all app states

## 🔄 Complete Flow Verification

1. **Admin assigns job** → Cloud Function triggers
2. **FCM token retrieved** → Notification sent
3. **Device receives notification** → Shows in tray
4. **User taps notification** → App opens
5. **Navigation occurs** → Assigned job detail screen
6. **User sees job details** → Can take action

This ensures the complete notification flow works end-to-end!
