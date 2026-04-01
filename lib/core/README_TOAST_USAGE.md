# Complete Toast Usage Guide for Skillzaar App

This guide shows you ALL the different types of toast messages you can display to users in your app, including job requests, location services, and other important notifications.

## 🎯 Quick Reference - All Toast Types

| Toast Type | Color | Icon | When to Use |
|------------|-------|------|-------------|
| **Success** | 🟢 Green | ✓ | Job accepted, profile updated, payment successful |
| **Error** | 🔴 Red | ✗ | Connection failed, permission denied, errors |
| **Warning** | 🟠 Orange | ⚠ | Low balance, incomplete profile, warnings |
| **Info** | 🔵 Blue | ℹ | General information, tips, updates |
| **Location** | 🟣 Purple | 📍 | Location enabled, GPS active, area changes |
| **Job Request** | 🔵🔘 Blue Grey | 💼 | Job status, requests, work notifications |

## 🚀 How to Use in Your App

### 1. **Job Request Notifications** (Most Important!)

```dart
// When a job request is accepted
context.read<UIStateProvider>().showAnimatedJobRequestToast(
  context,
  '🎉 Job Request Accepted! You can now navigate to the location.',
);

// When a job request is pending
context.read<UIStateProvider>().showAnimatedInfoToast(
  context,
  'Job Status',
  'Your job request is being reviewed. Please wait.',
);

// When a job request is rejected
context.read<UIStateProvider>().showAnimatedErrorToast(
  context,
  'Job Request Rejected',
  'Sorry, your job request was not accepted this time.',
);

// When a job is completed
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Job Completed!',
  'Great work! The job has been marked as completed.',
);
```

### 2. **Location Services Notifications**

```dart
// When location permission is granted
context.read<UIStateProvider>().showAnimatedLocationToast(
  context,
  '📍 Location access granted! GPS is now active.',
);

// When location is being searched
context.read<UIStateProvider>().showAnimatedInfoToast(
  context,
  'Searching Location',
  'Please wait while we find nearby jobs...',
);

// When location is found
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Location Found!',
  'We found 5 jobs near your current location.',
);

// When location permission is denied
context.read<UIStateProvider>().showAnimatedErrorToast(
  context,
  'Location Access Denied',
  'Please enable location services to find nearby jobs.',
);
```

### 3. **Authentication & Profile Notifications**

```dart
// When user successfully logs in
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Welcome Back!',
  'Successfully logged in to your account.',
);

// When profile is updated
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Profile Updated!',
  'Your profile information has been saved successfully.',
);

// When phone verification is successful
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Phone Verified!',
  'Your phone number has been verified successfully.',
);

// When there's a login error
context.read<UIStateProvider>().showAnimatedErrorToast(
  context,
  'Login Failed',
  'Invalid phone number or OTP. Please try again.',
);
```

### 4. **Payment & Subscription Notifications**

```dart
// When payment is successful
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Payment Successful!',
  'Your monthly subscription has been activated.',
);

// When payment fails
context.read<UIStateProvider>().showAnimatedErrorToast(
  context,
  'Payment Failed',
  'Unable to process payment. Please check your card details.',
);

// When subscription is expiring
context.read<UIStateProvider>().showAnimatedWarningToast(
  context,
  'Subscription Expiring',
  'Your subscription expires in 3 days. Please renew.',
);
```

### 5. **Network & Connection Notifications**

```dart
// When connection is lost
context.read<UIStateProvider>().showAnimatedErrorToast(
  context,
  'Connection Lost',
  'No internet connection. Please check your network.',
);

// When connection is restored
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Connected!',
  'Internet connection restored. You can continue.',
);

// When data is syncing
context.read<UIStateProvider>().showAnimatedInfoToast(
  context,
  'Syncing Data',
  'Please wait while we sync your latest data...',
);
```

### 6. **File Upload & Media Notifications**

```dart
// When profile picture is uploaded
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Photo Uploaded!',
  'Your profile picture has been updated successfully.',
);

// When document upload fails
context.read<UIStateProvider>().showAnimatedErrorToast(
  context,
  'Upload Failed',
  'Unable to upload document. Please try again.',
);

// When portfolio is saved
context.read<UIStateProvider>().showAnimatedSuccessToast(
  context,
  'Portfolio Saved!',
  'Your portfolio has been updated successfully.',
);
```

## 🔧 Implementation Examples

### Example 1: Job Request Flow

```dart
class JobRequestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // Show loading
              context.read<UIStateProvider>().startLoading();
              
              try {
                // Simulate API call
                await Future.delayed(Duration(seconds: 2));
                
                // Show success toast
                context.read<UIStateProvider>().showAnimatedJobRequestToast(
                  context,
                  '🎉 Congratulations! Your job request has been accepted. You can now navigate to the job location.',
                );
                
                // Navigate to job details
                Navigator.pushNamed(context, '/job-details');
                
              } catch (e) {
                // Show error toast
                context.read<UIStateProvider>().showAnimatedErrorToast(
                  context,
                  'Request Failed',
                  'Unable to submit job request. Please try again.',
                );
              } finally {
                context.read<UIStateProvider>().stopLoading();
              }
            },
            child: Text('Submit Job Request'),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Location Permission Flow

```dart
class LocationPermissionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              try {
                // Request location permission
                final permission = await Permission.location.request();
                
                if (permission.isGranted) {
                  // Show success toast
                  context.read<UIStateProvider>().showAnimatedLocationToast(
                    context,
                    '📍 Location access granted! You can now find nearby jobs.',
                  );
                  
                  // Continue to next screen
                  Navigator.pushNamed(context, '/find-jobs');
                  
                } else {
                  // Show warning toast
                  context.read<UIStateProvider>().showAnimatedWarningToast(
                    context,
                    'Location Required',
                    'Location access is needed to find jobs near you.',
                  );
                }
                
              } catch (e) {
                // Show error toast
                context.read<UIStateProvider>().showAnimatedErrorToast(
                  context,
                  'Permission Error',
                  'Unable to request location permission.',
                );
              }
            },
            child: Text('Enable Location'),
          ),
        ],
      ),
    );
  }
}
```

### Example 3: Profile Update Flow

```dart
class ProfileUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              try {
                // Show loading
                context.read<UIStateProvider>().startLoading();
                
                // Simulate profile update
                await Future.delayed(Duration(seconds: 1));
                
                // Show success toast
                context.read<UIStateProvider>().showAnimatedSuccessToast(
                  context,
                  'Profile Updated!',
                  'Your profile information has been saved successfully.',
                );
                
                // Go back
                Navigator.pop(context);
                
              } catch (e) {
                // Show error toast
                context.read<UIStateProvider>().showAnimatedErrorToast(
                  context,
                  'Update Failed',
                  'Unable to update profile. Please check your connection.',
                );
              } finally {
                context.read<UIStateProvider>().stopLoading();
              }
            },
            child: Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}
```

## 📱 Toast Duration Guidelines

- **Success Messages**: 3 seconds (user can read quickly)
- **Error Messages**: 4 seconds (user needs more time to understand)
- **Info Messages**: 3 seconds (general information)
- **Warning Messages**: 4 seconds (important warnings)
- **Location Messages**: 3 seconds (quick status updates)
- **Job Request Messages**: 4 seconds (important notifications)

## 🎨 Customization Options

### Custom Duration
```dart
// Show a toast for 5 seconds
ToastOverlay.instance.showToast(
  context: context,
  title: 'Important Notice',
  message: 'This message will stay visible for 5 seconds',
  duration: Duration(seconds: 5),
);
```

### Custom Toast with Action
```dart
// Show toast with action button
ToastService.instance.showToast(
  context: context,
  title: 'New Message',
  message: 'You have a new message from client',
  type: ToastType.info,
  action: SnackBarAction(
    label: 'View',
    onPressed: () {
      Navigator.pushNamed(context, '/messages');
    },
  ),
);
```

### Toast Without Close Button
```dart
// Show toast without close button
ToastOverlay.instance.showToast(
  context: context,
  title: 'Processing',
  message: 'Please wait while we process your request...',
  showCloseButton: false,
  duration: Duration(seconds: 2),
);
```

## 🚨 Best Practices

1. **Use Animated Toasts** for important notifications (job status, location, etc.)
2. **Use Regular Toasts** for simple confirmations and quick messages
3. **Keep Messages Clear** - users should understand immediately
4. **Use Appropriate Types** - match the toast type to the message content
5. **Don't Overwhelm Users** - show one toast at a time
6. **Use Emojis Sparingly** - only for celebration or important messages

## 🔄 Integration with Your Existing Code

The toast system is already integrated with your `UIStateProvider`. You can use it anywhere in your app:

```dart
// In any widget
Widget build(BuildContext context) {
  return Consumer<UIStateProvider>(
    builder: (context, uiProvider, child) {
      return YourWidget();
    },
  );
}

// Or directly access the provider
void someFunction(BuildContext context) {
  context.read<UIStateProvider>().showAnimatedSuccessToast(
    context,
    'Success!',
    'Operation completed successfully.',
  );
}
```

## 📍 Key Locations to Use Toasts

1. **Job Request Screens** - When requests are submitted/accepted/rejected
2. **Location Screens** - When permissions are granted/denied
3. **Authentication Screens** - When login/signup succeeds/fails
4. **Profile Screens** - When updates are saved
5. **Payment Screens** - When transactions succeed/fail
6. **Network Operations** - When connections are lost/restored
7. **File Uploads** - When documents/photos are uploaded
8. **Navigation** - When users can proceed to next steps

This comprehensive toast system will make your app much more user-friendly and provide clear feedback for all important actions! 🎉
