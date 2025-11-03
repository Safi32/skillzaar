# Worker Tracking Feature

This feature allows job posters to track skilled workers in real-time on a map interface.

## Features

### For Skilled Workers
- **Automatic Location Tracking**: Location is automatically tracked when workers log in
- **Real-time Updates**: Location updates every 30 seconds while the app is active
- **Online/Offline Status**: Workers are marked as online when active, offline when logged out
- **Background Tracking**: Location continues to update while the app is in the foreground

### For Job Posters
- **Real-time Map View**: See worker location on Google Maps
- **Distance Calculation**: View distance between job location and worker
- **Worker Status**: See if worker is online/offline and last seen time
- **Multiple Markers**: 
  - Blue marker: Job poster's current location
  - Red marker: Job location
  - Green marker: Worker's current location

## Implementation Details

### Location Tracking Service
- **File**: `lib/core/services/location_tracking_service.dart`
- **Features**:
  - Singleton pattern for global access
  - Automatic permission handling
  - Periodic location updates (30 seconds)
  - Firestore integration for storing location data
  - Distance calculation utilities

### Map Widget
- **File**: `lib/presentation/widgets/worker_tracking_map.dart`
- **Features**:
  - Google Maps integration
  - Real-time marker updates
  - Distance display
  - Refresh functionality
  - Online/offline status indicators

### Tracking Screen
- **File**: `lib/presentation/screens/job_poster/worker_tracking_screen.dart`
- **Features**:
  - Full-screen map view
  - Worker information display
  - Job details
  - Refresh button

## Usage

### For Job Posters
1. Go to a job with an accepted worker
2. Click "Track Worker Location" button
3. View real-time worker location on map
4. Use refresh button to update location

### For Skilled Workers
- Location tracking starts automatically when logging in
- No additional setup required
- Location updates every 30 seconds

## Data Structure

### Firestore Collections

#### SkilledWorkers Collection
```dart
{
  'currentLocation': GeoPoint(latitude, longitude),
  'lastLocationUpdate': Timestamp,
  'isOnline': bool,
  'lastSeen': Timestamp,
  // ... other worker fields
}
```

## Permissions Required

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track worker positions</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track worker positions</string>
```

## Configuration

### Google Maps API Key
- Already configured in `android/app/src/main/AndroidManifest.xml`
- Key: `AIzaSyCeozEFCHJyX5syiB-oz2UNMDJvS4gFhb0`

### Location Update Interval
- Default: 30 seconds
- Configurable in `LocationTrackingService._updateInterval`

## Security Considerations

- Location data is only stored for active workers
- Data is automatically cleaned up when workers log out
- No location history is permanently stored
- Workers can control their location sharing by logging out

## Troubleshooting

### Common Issues
1. **Location not updating**: Check if location permissions are granted
2. **Map not loading**: Verify Google Maps API key is correct
3. **Worker not visible**: Ensure worker is logged in and location tracking is active

### Debug Information
- Check console logs for location tracking errors
- Verify Firestore data structure matches expected format
- Ensure network connectivity for real-time updates
