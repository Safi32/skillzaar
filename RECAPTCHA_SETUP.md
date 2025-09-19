# reCAPTCHA Setup Guide for Skillzaar

This guide explains how to set up reCAPTCHA verification for phone authentication in your Skillzaar app.

## Overview

The app now supports dynamic OTP with reCAPTCHA verification for both job posters and skilled workers. reCAPTCHA is automatically handled by Firebase Auth and will appear when needed.

## What's Been Implemented

### 1. Dynamic OTP Authentication
- ✅ Removed all hardcoded test phone numbers
- ✅ Firebase Auth now sends real OTP to user's phone number
- ✅ Works for both job poster and skilled worker authentication

### 2. reCAPTCHA Integration
- ✅ Added reCAPTCHA service for web platforms
- ✅ Updated both OTP screens to show reCAPTCHA widget
- ✅ Firebase Auth automatically handles reCAPTCHA verification
- ✅ Mobile platforms don't require manual reCAPTCHA (handled automatically)

### 3. Files Modified/Created

#### New Files:
- `lib/core/services/recaptcha_service.dart` - reCAPTCHA service
- `lib/presentation/widgets/recaptcha_widget.dart` - reCAPTCHA UI widget
- `RECAPTCHA_SETUP.md` - This setup guide

#### Modified Files:
- `pubspec.yaml` - Added flutter_web_auth dependency
- `web/index.html` - Added Firebase and reCAPTCHA scripts
- `lib/presentation/providers/phone_auth_provider.dart` - Added reCAPTCHA support
- `lib/presentation/providers/skilled_worker_provider.dart` - Added reCAPTCHA support
- `lib/presentation/screens/job_poster/otp_screen.dart` - Added reCAPTCHA widget
- `lib/presentation/screens/skilled_worker/otp_screen.dart` - Added reCAPTCHA widget

## Firebase Configuration Required

### 1. Enable Phone Authentication
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Phone" provider
3. Add your app's SHA-1 fingerprint for Android
4. Configure your domain for web

### 2. Configure reCAPTCHA (for Web)
1. Go to Google reCAPTCHA Admin Console
2. Create a new site:
   - Label: "Skillzaar Web App"
   - reCAPTCHA type: "reCAPTCHA v2" → "I'm not a robot" Checkbox
   - Domains: Add your web domain (e.g., `your-app.web.app`)
3. Copy the Site Key and Secret Key

### 3. Update Firebase Configuration
1. In Firebase Console → Authentication → Settings → Authorized domains
2. Add your web domain
3. The reCAPTCHA will be automatically configured by Firebase

## Testing the Implementation

### Mobile Testing
1. Run the app on Android/iOS device
2. Enter a real phone number
3. Firebase will send a real OTP to the phone
4. Enter the OTP to complete authentication

### Web Testing
1. Run the app on web: `flutter run -d chrome`
2. Enter a real phone number
3. reCAPTCHA will appear automatically
4. Complete reCAPTCHA verification
5. Firebase will send a real OTP to the phone
6. Enter the OTP to complete authentication

## Important Notes

### Security
- ✅ All test phone numbers have been removed
- ✅ Only real phone numbers can be used for authentication
- ✅ reCAPTCHA prevents spam and abuse
- ✅ Firebase handles all security aspects

### Platform Differences
- **Mobile (Android/iOS)**: reCAPTCHA is handled automatically by Firebase
- **Web**: reCAPTCHA widget appears and must be completed before OTP is sent

### Error Handling
- Network errors are properly handled
- reCAPTCHA failures show user-friendly messages
- OTP verification errors are displayed clearly

## Troubleshooting

### Common Issues

1. **reCAPTCHA not appearing on web**
   - Check if you're running on web platform
   - Verify Firebase configuration
   - Check browser console for errors

2. **OTP not being sent**
   - Verify phone number format (+country code)
   - Check Firebase Authentication settings
   - Ensure phone provider is enabled

3. **reCAPTCHA verification fails**
   - Check internet connection
   - Try refreshing the page
   - Verify domain is authorized in Firebase

### Debug Steps
1. Check console logs for error messages
2. Verify Firebase project configuration
3. Test with different phone numbers
4. Check network connectivity

## Next Steps

1. **Deploy to Firebase Hosting** (for web testing)
2. **Test with real users**
3. **Monitor Firebase Authentication logs**
4. **Configure additional security rules if needed**

## Support

If you encounter any issues:
1. Check the console logs
2. Verify Firebase configuration
3. Test on different platforms
4. Check Firebase Authentication documentation

The implementation is now complete and ready for production use with proper Firebase configuration.
