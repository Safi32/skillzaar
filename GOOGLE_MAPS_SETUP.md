# Google Maps Integration Setup Guide

This guide explains how to set up Google Maps integration for the Skillzaar app to enable real-time address selection when posting jobs.

## Prerequisites

1. Google Cloud Console account
2. Flutter project with the required dependencies

## Dependencies

The following packages are already added to `pubspec.yaml`:

```yaml
dependencies:
  google_maps_flutter: ^2.6.0
  google_places_flutter: ^2.0.6
  geolocator: ^11.0.0
  geocoding: ^2.2.0
```

## Setup Steps

### 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key to your app's bundle ID for security

### 2. Update Configuration

Replace the API key in `lib/core/config/google_maps_config.dart`:

```dart
class GoogleMapsConfig {
  // Replace with your actual Google Maps API key
  static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  
  static const String defaultCountry = 'pk'; // Pakistan
  static const double defaultZoom = 15.0;
}
```

### 3. Android Configuration

Add the following to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

### 4. iOS Configuration

Add the following to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 5. Location Permissions

#### Android
Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS
Add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to help you select job locations.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to help you select job locations.</string>
```

## Features

The Google Maps integration provides:

1. **Interactive Map**: Users can tap on the map to select locations
2. **Search Functionality**: Google Places autocomplete for location search
3. **Current Location**: Automatic detection of user's current location
4. **Real-time Address**: Automatic address resolution from coordinates
5. **Draggable Markers**: Users can fine-tune location by dragging markers
6. **Coordinate Display**: Shows exact latitude and longitude coordinates

## Usage

The location picker is integrated into the job posting screen. Users can:

1. Search for locations using the search bar
2. Tap on the map to select a location
3. Use the current location button
4. Drag markers to adjust the exact position
5. View the selected address and coordinates

## Security Notes

- Never commit your API key to version control
- Use API key restrictions in Google Cloud Console
- Consider using environment variables for production builds
- Monitor API usage to avoid unexpected charges

## Troubleshooting

### Common Issues

1. **Map not loading**: Check API key and internet connection
2. **Location not working**: Ensure location permissions are granted
3. **Search not working**: Verify Places API is enabled
4. **Build errors**: Ensure all dependencies are properly installed

### Commands

```bash
# Install dependencies
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Support

For issues related to:
- Google Maps API: Check Google Cloud Console documentation
- Flutter packages: Check package documentation on pub.dev
- App-specific issues: Check the app's error logs
