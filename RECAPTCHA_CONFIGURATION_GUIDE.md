# reCAPTCHA Configuration Guide for Skillzaar

## Current Status
Your Flutter app has reCAPTCHA integration implemented, but you need to configure the actual reCAPTCHA site key in Firebase.

## Steps to Fix reCAPTCHA Configuration

### 1. Create reCAPTCHA Site Key

1. Go to [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin)
2. Click "Create" to add a new site
3. Fill in the details:
   - **Label**: "Skillzaar Web App"
   - **reCAPTCHA type**: Select "reCAPTCHA v2" → "I'm not a robot" Checkbox
   - **Domains**: Add your domains:
     - `localhost` (for development)
     - `skillzaar-bcb0f.firebaseapp.com` (your Firebase hosting domain)
     - Any custom domain you plan to use
4. Accept the Terms of Service
5. Click "Submit"
6. Copy the **Site Key** (starts with "6Lf...")

### 2. Update Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `skillzaar-bcb0f`
3. Go to **Authentication** → **Settings** → **Authorized domains**
4. Add your domains if not already present:
   - `localhost`
   - `skillzaar-bcb0f.firebaseapp.com`

### 3. Update Your Code

Replace the placeholder reCAPTCHA site key in these files:

#### File: `web/index.html`
```javascript
// Replace this line:
firebase.appCheck().activate('6Lf...', true); // Replace with your reCAPTCHA site key

// With your actual site key:
firebase.appCheck().activate('6LfYOUR_ACTUAL_SITE_KEY_HERE', true);
```

#### File: `lib/core/services/recaptcha_service.dart`
```dart
// Replace this line:
return '6Lf...'; // Replace with your actual site key

// With your actual site key:
return '6LfYOUR_ACTUAL_SITE_KEY_HERE';
```

### 4. Test the Configuration

1. **For Web Testing**:
   ```bash
   flutter run -d chrome
   ```
   - Navigate to the OTP screen
   - Enter a phone number
   - reCAPTCHA should appear automatically
   - Complete verification and send OTP

2. **For Mobile Testing**:
   ```bash
   flutter run -d android
   # or
   flutter run -d ios
   ```
   - reCAPTCHA is handled automatically by Firebase
   - No additional configuration needed

### 5. Production Deployment

When deploying to production:

1. **Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```

2. **Update reCAPTCHA domains** to include your production domain

3. **Test on production** to ensure reCAPTCHA works correctly

## Troubleshooting

### Common Issues:

1. **"No Recaptcha Enterprise siteKey configured"**
   - Solution: Follow steps 1-3 above to configure the site key

2. **reCAPTCHA not appearing on web**
   - Check if you're running on web platform
   - Verify the site key is correct
   - Check browser console for errors

3. **"Invalid domain" error**
   - Add your domain to reCAPTCHA configuration
   - Update Firebase authorized domains

4. **reCAPTCHA verification fails**
   - Check internet connection
   - Verify site key is correct
   - Try refreshing the page

### Debug Steps:

1. Open browser developer tools (F12)
2. Check Console tab for errors
3. Look for Firebase initialization messages
4. Verify reCAPTCHA script is loading

## Security Notes

- Never expose your reCAPTCHA **Secret Key** in client-side code
- Only use the **Site Key** in your Flutter app
- The Secret Key should only be used on your backend server
- Regularly rotate your keys for security

## Next Steps

After completing the configuration:

1. Test the complete authentication flow
2. Deploy to Firebase Hosting
3. Test with real users
4. Monitor Firebase Authentication logs
5. Set up monitoring for reCAPTCHA success/failure rates

Your app is now ready for production use with proper reCAPTCHA security!
