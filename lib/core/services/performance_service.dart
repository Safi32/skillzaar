import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for handling heavy computations in isolates to prevent UI blocking
class PerformanceService {
  /// Calculate distance between two points using isolate for better performance
  static Future<double> calculateDistanceInIsolate({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) async {
    try {
      final result = await compute(_calculateDistance, {
        'lat1': lat1,
        'lon1': lon1,
        'lat2': lat2,
        'lon2': lon2,
      });
      return result;
    } catch (e) {
      debugPrint('Error calculating distance in isolate: $e');
      // Fallback to main thread calculation
      return _calculateDistance({
        'lat1': lat1,
        'lon1': lon1,
        'lat2': lat2,
        'lon2': lon2,
      });
    }
  }

  /// Process large datasets in isolate
  static Future<List<Map<String, dynamic>>> processJobDataInIsolate({
    required List<Map<String, dynamic>> jobs,
    required double? userLat,
    required double? userLng,
    required double radius,
  }) async {
    try {
      final result = await compute(_processJobData, {
        'jobs': jobs,
        'userLat': userLat,
        'userLng': userLng,
        'radius': radius,
      });
      return result;
    } catch (e) {
      debugPrint('Error processing job data in isolate: $e');
      // Fallback to main thread processing
      return _processJobData({
        'jobs': jobs,
        'userLat': userLat,
        'userLng': userLng,
        'radius': radius,
      });
    }
  }

  /// Search and filter services in isolate
  static Future<List<Map<String, dynamic>>> searchServicesInIsolate({
    required String query,
    required List<Map<String, dynamic>> allServices,
  }) async {
    try {
      final result = await compute(_searchServices, {
        'query': query,
        'allServices': allServices,
      });
      return result;
    } catch (e) {
      debugPrint('Error searching services in isolate: $e');
      // Fallback to main thread search
      return _searchServices({'query': query, 'allServices': allServices});
    }
  }

  /// Process image data in isolate (for future image processing features)
  static Future<Map<String, dynamic>> processImageInIsolate({
    required List<int> imageBytes,
    required int width,
    required int height,
  }) async {
    try {
      final result = await compute(_processImage, {
        'imageBytes': imageBytes,
        'width': width,
        'height': height,
      });
      return result;
    } catch (e) {
      debugPrint('Error processing image in isolate: $e');
      return {'error': e.toString()};
    }
  }

  /// Batch process multiple calculations in isolate
  static Future<List<double>> batchCalculateDistancesInIsolate({
    required List<Map<String, double>> coordinates,
    required double userLat,
    required double userLng,
  }) async {
    try {
      final result = await compute(_batchCalculateDistances, {
        'coordinates': coordinates,
        'userLat': userLat,
        'userLng': userLng,
      });
      return result;
    } catch (e) {
      debugPrint('Error batch calculating distances in isolate: $e');
      // Fallback to main thread calculation
      return _batchCalculateDistances({
        'coordinates': coordinates,
        'userLat': userLat,
        'userLng': userLng,
      });
    }
  }

  /// Sort and filter large lists in isolate
  static Future<List<Map<String, dynamic>>> sortAndFilterInIsolate({
    required List<Map<String, dynamic>> items,
    required String sortBy,
    required bool ascending,
    required Map<String, dynamic> filters,
  }) async {
    try {
      final result = await compute(_sortAndFilter, {
        'items': items,
        'sortBy': sortBy,
        'ascending': ascending,
        'filters': filters,
      });
      return result;
    } catch (e) {
      debugPrint('Error sorting and filtering in isolate: $e');
      // Fallback to main thread processing
      return _sortAndFilter({
        'items': items,
        'sortBy': sortBy,
        'ascending': ascending,
        'filters': filters,
      });
    }
  }
}

/// Isolate functions - these run in separate isolates

/// Calculate distance between two points (Haversine formula)
double _calculateDistance(Map<String, dynamic> params) {
  final lat1 = params['lat1'] as double;
  final lon1 = params['lon1'] as double;
  final lat2 = params['lat2'] as double;
  final lon2 = params['lon2'] as double;

  const double R = 6371; // Earth's radius in kilometers
  final double dLat = (lat2 - lat1) * pi / 180;
  final double dLon = (lon2 - lon1) * pi / 180;
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// Process job data with distance calculations and filtering
List<Map<String, dynamic>> _processJobData(Map<String, dynamic> params) {
  final jobs = params['jobs'] as List<Map<String, dynamic>>;
  final userLat = params['userLat'] as double?;
  final userLng = params['userLng'] as double?;
  final radius = params['radius'] as double;

  if (userLat == null || userLng == null) {
    return jobs;
  }

  final processedJobs = <Map<String, dynamic>>[];

  for (final job in jobs) {
    final lat =
        job['Latitude'] is double
            ? job['Latitude']
            : (job['Latitude'] as num?)?.toDouble();
    final lng =
        job['Longitude'] is double
            ? job['Longitude']
            : (job['Longitude'] as num?)?.toDouble();

    if (lat != null && lng != null) {
      final distance = _calculateDistance({
        'lat1': userLat,
        'lon1': userLng,
        'lat2': lat,
        'lon2': lng,
      });

      if (distance <= radius) {
        final processedJob = Map<String, dynamic>.from(job);
        processedJob['distance'] = distance;
        processedJobs.add(processedJob);
      }
    }
  }

  // Sort by distance
  processedJobs.sort((a, b) {
    final distanceA = a['distance'] as double? ?? double.infinity;
    final distanceB = b['distance'] as double? ?? double.infinity;
    return distanceA.compareTo(distanceB);
  });

  return processedJobs;
}

/// Search services with fuzzy matching
List<Map<String, dynamic>> _searchServices(Map<String, dynamic> params) {
  final query = (params['query'] as String).toLowerCase();
  final allServices = params['allServices'] as List<Map<String, dynamic>>;

  if (query.isEmpty) return allServices;

  final results = <Map<String, dynamic>>[];

  for (final service in allServices) {
    final serviceName = (service['name'] ?? '').toString().toLowerCase();
    final serviceDescription =
        (service['description'] ?? '').toString().toLowerCase();
    final serviceCategory =
        (service['category'] ?? '').toString().toLowerCase();

    // Simple fuzzy matching
    if (serviceName.contains(query) ||
        serviceDescription.contains(query) ||
        serviceCategory.contains(query)) {
      results.add(service);
    }
  }

  // Sort by relevance (exact match first, then partial match)
  results.sort((a, b) {
    final nameA = (a['name'] ?? '').toString().toLowerCase();
    final nameB = (b['name'] ?? '').toString().toLowerCase();

    final exactMatchA = nameA == query ? 1 : 0;
    final exactMatchB = nameB == query ? 1 : 0;

    if (exactMatchA != exactMatchB) {
      return exactMatchB.compareTo(exactMatchA);
    }

    return nameA.compareTo(nameB);
  });

  return results;
}

/// Process image data (placeholder for future image processing)
Map<String, dynamic> _processImage(Map<String, dynamic> params) {
  final imageBytes = params['imageBytes'] as List<int>;
  final width = params['width'] as int;
  final height = params['height'] as int;

  // Placeholder image processing logic
  // In a real implementation, this would process the image bytes
  return {
    'processed': true,
    'width': width,
    'height': height,
    'size': imageBytes.length,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
}

/// Batch calculate distances for multiple coordinates
List<double> _batchCalculateDistances(Map<String, dynamic> params) {
  final coordinates = params['coordinates'] as List<Map<String, double>>;
  final userLat = params['userLat'] as double;
  final userLng = params['userLng'] as double;

  final distances = <double>[];

  for (final coord in coordinates) {
    final lat = coord['lat']!;
    final lng = coord['lng']!;
    final distance = _calculateDistance({
      'lat1': userLat,
      'lon1': userLng,
      'lat2': lat,
      'lon2': lng,
    });
    distances.add(distance);
  }

  return distances;
}

/// Sort and filter items
List<Map<String, dynamic>> _sortAndFilter(Map<String, dynamic> params) {
  final items = params['items'] as List<Map<String, dynamic>>;
  final sortBy = params['sortBy'] as String;
  final ascending = params['ascending'] as bool;
  final filters = params['filters'] as Map<String, dynamic>;

  // Apply filters
  var filteredItems =
      items.where((item) {
        for (final entry in filters.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value == null) continue;

          final itemValue = item[key];
          if (itemValue == null) return false;

          if (value is String) {
            if (!itemValue.toString().toLowerCase().contains(
              value.toLowerCase(),
            )) {
              return false;
            }
          } else if (value is num) {
            if (itemValue is! num || itemValue != value) {
              return false;
            }
          } else if (value is bool) {
            if (itemValue is! bool || itemValue != value) {
              return false;
            }
          }
        }
        return true;
      }).toList();

  // Sort items
  filteredItems.sort((a, b) {
    final aValue = a[sortBy];
    final bValue = b[sortBy];

    if (aValue == null && bValue == null) return 0;
    if (aValue == null) return ascending ? 1 : -1;
    if (bValue == null) return ascending ? -1 : 1;

    int comparison;
    if (aValue is num && bValue is num) {
      comparison = aValue.compareTo(bValue);
    } else if (aValue is String && bValue is String) {
      comparison = aValue.compareTo(bValue);
    } else if (aValue is DateTime && bValue is DateTime) {
      comparison = aValue.compareTo(bValue);
    } else {
      comparison = aValue.toString().compareTo(bValue.toString());
    }

    return ascending ? comparison : -comparison;
  });

  return filteredItems;
}
