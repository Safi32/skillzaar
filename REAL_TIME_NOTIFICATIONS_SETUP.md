# Real-Time Notifications Setup Guide

## Overview
This guide explains how to set up real-time notifications for job events like assignment, completion, and cancellation. The system uses Firebase Cloud Messaging (FCM) with Cloud Functions to send notifications automatically when events occur in the admin panel.

## 🔧 Setup Steps

### 1. Deploy Cloud Functions

Navigate to the functions directory and deploy the functions:

```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Cloud Functions Created

The following Cloud Functions have been created:

#### `onJobAssigned`
- **Trigger**: When a document is created in `AssignedJobs` collection
- **Action**: Sends notifications to both skilled worker and job poster
- **Notifications**:
  - Skilled Worker: "🎉 Job Assigned! You have been assigned to: [Job Title]"
  - Job Poster: "✅ Worker Assigned! [Worker Name] has been assigned to your job: [Job Title]"

#### `onJobCompleted`
- **Trigger**: When `assignmentStatus` changes to "completed" in `AssignedJobs`
- **Action**: Notifies skilled worker to rate the job poster
- **Notification**: "⭐ Rate Your Client [Client Name] completed the job: [Job Title]. Please rate your experience."

#### `onWorkerRatingCompleted`
- **Trigger**: When `workerRatingCompleted` changes to true in `AssignedJobs`
- **Action**: Notifies job poster that worker has rated them
- **Notification**: "⭐ Rating Received [Worker Name] has rated your job: [Job Title]. Thank you for using our service!"

#### `onJobCancelled`
- **Trigger**: When `assignmentStatus` changes to "cancelled" in `AssignedJobs`
- **Action**: Notifies both parties about job cancellation
- **Notification**: "❌ Job Cancelled The job '[Job Title]' has been cancelled."

### 3. FCM Token Storage

FCM tokens are automatically saved to the appropriate user collections:
- **SkilledWorkers**: `fcmToken` field
- **JobPosters**: `fcmToken` field

### 4. Notification Types

The system supports the following notification types:

| Type | Description | Recipients | Action |
|------|-------------|------------|--------|
| `job_assigned` | Job assigned by admin | Worker + Job Poster | Navigate to assigned job detail |
| `job_completed` | Job completed by poster | Skilled Worker | Navigate to rate client screen |
| `worker_rating_completed` | Worker rated job poster | Job Poster | Navigate to home |
| `job_cancelled` | Job cancelled | Both parties | Navigate to home |
| `job_posting` | New job posted | All skilled workers | Navigate to jobs screen |

## 📱 Mobile App Integration

### Notification Handler
The app automatically handles notification taps and navigates to the appropriate screen:

```dart
// Example: Job assigned notification
{
  "type": "job_assigned",
  "assignedJobId": "assignment_123",
  "userType": "skilled_worker",
  "jobId": "job_456"
}
```

### Navigation Flow
1. **Job Assigned** → Assigned Job Detail Screen
2. **Job Completed** → Rate Job Poster Screen
3. **Rating Completed** → Home Screen
4. **Job Cancelled** → Home Screen
5. **New Job Posted** → Jobs Screen

## 🔄 Complete Workflow

### 1. Job Assignment (Admin Panel)
1. Admin assigns job in web panel
2. Document created in `AssignedJobs` collection
3. `onJobAssigned` function triggers
4. Notifications sent to both worker and job poster
5. Both users see assigned job detail screen on next app open

### 2. Job Completion (Job Poster)
1. Job poster marks job as completed
2. `assignmentStatus` updated to "completed"
3. `onJobCompleted` function triggers
4. Skilled worker receives notification to rate client
5. Worker navigated to rating screen on next app open

### 3. Worker Rating (Skilled Worker)
1. Worker rates job poster
2. `workerRatingCompleted` updated to true
3. `onWorkerRatingCompleted` function triggers
4. Job poster receives rating confirmation
5. Both users can access home screens

### 4. Job Cancellation
1. Either party cancels job
2. `assignmentStatus` updated to "cancelled"
3. `onJobCancelled` function triggers
4. Both parties notified of cancellation
5. Both users navigated to home screens

## 🛠️ Testing

### Test Job Assignment
1. Create a job in the admin panel
2. Assign it to a skilled worker
3. Check that both worker and job poster receive notifications
4. Verify navigation to assigned job detail screen

### Test Job Completion
1. Complete a job as job poster
2. Check that skilled worker receives rating notification
3. Verify navigation to rate client screen

### Test Rating Flow
1. Rate job poster as skilled worker
2. Check that job poster receives rating confirmation
3. Verify both users can access home screens

## 📊 Monitoring

### Cloud Functions Logs
Monitor function execution in Firebase Console:
1. Go to Functions section
2. Click on individual function
3. View logs for execution details

### FCM Delivery Reports
Check notification delivery in Firebase Console:
1. Go to Cloud Messaging section
2. View delivery reports
3. Monitor success/failure rates

## 🔧 Troubleshooting

### Common Issues

1. **Notifications not received**
   - Check FCM token is saved in user collection
   - Verify Cloud Functions are deployed
   - Check function logs for errors

2. **Navigation not working**
   - Ensure navigator key is properly initialized
   - Check notification data format
   - Verify route names match

3. **Duplicate notifications**
   - Check for multiple function triggers
   - Verify document update logic
   - Review function conditions

### Debug Steps

1. Check Cloud Functions logs
2. Verify FCM token storage
3. Test notification data format
4. Check app notification permissions
5. Verify route configurations

## 🚀 Production Deployment

### Prerequisites
- Firebase project configured
- Cloud Functions enabled
- FCM enabled
- Admin panel connected to same Firebase project

### Deployment Checklist
- [ ] Cloud Functions deployed
- [ ] FCM tokens being saved
- [ ] Notification permissions granted
- [ ] Routes properly configured
- [ ] Testing completed
- [ ] Monitoring set up

## 📈 Performance Considerations

### Cloud Functions
- Functions are triggered only on document changes
- Efficient FCM token lookup
- Error handling for missing tokens
- Batch operations where possible

### Mobile App
- Background message handling
- Efficient notification processing
- Proper navigation state management
- Error handling for failed notifications

## 🔐 Security

### FCM Token Security
- Tokens are user-specific
- No sensitive data in notifications
- Proper error handling
- Token refresh handling

### Cloud Functions Security
- Proper authentication checks
- Input validation
- Error logging without sensitive data
- Rate limiting considerations

This system provides a complete real-time notification solution for your job management platform!
