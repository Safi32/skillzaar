import 'package:skillzaar/core/examples/services/user_data_service.dart';


/// Simple test to verify Firestore connection and user data creation
class FirestoreTest {
  /// Test basic Firestore connection
  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing Firestore connection...');
      final isConnected = await UserDataService.testConnection();

      if (isConnected) {
        print('✅ Firestore connection successful');
        return true;
      } else {
        print('❌ Firestore connection failed');
        return false;
      }
    } catch (e) {
      print('❌ Firestore test error: $e');
      return false;
    }
  }

  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    print('🧪 Running Firestore tests...');
    print('=' * 50);

    final results = <String, bool>{};

    // Test 1: Connection
    results['connection'] = await testConnection();

    // Print results
    print('\n📊 Test Results:');
    print('=' * 50);
    for (final entry in results.entries) {
      final status = entry.value ? '✅ PASS' : '❌ FAIL';
      print('${entry.key}: $status');
    }

    return results;
  }
}
