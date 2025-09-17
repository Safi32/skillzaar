# Firebase Phone Authentication Setup Guide

## Current Issue
Your app is failing to send OTP because reCAPTCHA Enterprise is not configured in your Firebase project.

## Error Messages
```
Failed to initialize reCAPTCHA config: No Recaptcha Enterprise siteKey configured
SecurityException: Unknown calling package name 'com.google.android.gms'
```

## Solution Steps

### 1. Enable reCAPTCHA Enterprise in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `skillzaar-bcb0f`
3. Go to **Authentication** → **Sign-in method**
4. Click on **Phone** provider
5. Enable **reCAPTCHA Enterprise** (not regular reCAPTCHA)
6. Follow the setup wizard to create a reCAPTCHA Enterprise key

### 2. Get Your reCAPTCHA Site Key

After enabling reCAPTCHA Enterprise:
1. Go to **Project Settings** → **General**
2. Scroll down to **reCAPTCHA Enterprise**
3. Copy the **Site Key** (starts with `6Lf...`)

### 3. Update Android Configuration

Replace the placeholder in `android/app/build.gradle.kts`:

```kotlin
resValue("string", "recaptcha_site_key", "YOUR_ACTUAL_SITE_KEY_HERE")
```

### 4. Add SHA-1 Fingerprint (Important!)

The SecurityException suggests a SHA-1 fingerprint mismatch:

1. Get your debug SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```

2. In Firebase Console:
   - Go to **Project Settings** → **General**
   - Scroll to **Your apps**
   - Click on your Android app
   - Add the SHA-1 fingerprint

### 5. Alternative: Use Test Phone Numbers (Temporary)

For immediate testing, you can use Firebase's test phone numbers:

1. In Firebase Console → **Authentication** → **Sign-in method** → **Phone**
2. Add test phone numbers:
   - `+1 650-555-3434` with code `123456`
   - `+1 650-555-3435` with code `123456`

### 6. Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## Verification

After setup, you should see:
- No reCAPTCHA errors in console
- OTP sent successfully to real phone numbers
- No SecurityException errors

## Current Status
- ✅ Firebase project configured
- ✅ Google Services plugin added
- ❌ reCAPTCHA Enterprise not enabled
- ❌ SHA-1 fingerprint may be missing
- ❌ reCAPTCHA site key not configured
