import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  /// Request location permissions
  static Future<bool> requestLocationPermissions() async {
    // Check if location permission is granted
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission if not granted
    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    // If permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  /// Check if location permission is permanently denied
  static Future<bool> isLocationPermissionPermanentlyDenied() async {
    return await Permission.location.isPermanentlyDenied;
  }
}
