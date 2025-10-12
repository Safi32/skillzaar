import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'skilled_worker_provider.dart';

class HomeProfileProvider with ChangeNotifier {
  final List<String> _portfolioImages = [];
  final List<String> _selectedCategories = [];
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();

  bool _isProfileComplete = false;
  bool _hasBasicInfo = false;
  bool _hasSkills = false;
  bool _hasExperience = false;
  bool _hasBio = false;
  bool _hasServiceType = false;

  String? _selectedServiceType;

  final List<String> allCategories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Cleaning',
    'Other',
  ];

  // Service types from job posting (same as SimpleServiceDropdown)
  static const List<String> serviceTypes = [
    'Cleaning Services',
    'Plumbing Services',
    'Carpentry & Furniture',
    'Painting & Finishing',
    'Masonry & Metalwork',
    'Roofing Services',
    'Glass & Installation',
    'Outdoor & Gardening',
    'Electrical Services',
    'Appliance Deep Cleaning',
    'Labour & Moving',
    'Car Care Services',
    'Water & Utility',
    'Catering & Events',
    'Residential & Commercial Construction',
    'Design & Planning',
    'Renovation & Finishing',
    'Specialized Works',
    'Outdoor Construction',
  ];

  // Getters
  List<String> get portfolioImages => List.unmodifiable(_portfolioImages);
  List<String> get selectedCategories => List.unmodifiable(_selectedCategories);
  bool get isProfileComplete => _isProfileComplete;
  bool get hasBasicInfo => _hasBasicInfo;
  bool get hasSkills => _hasSkills;
  bool get hasExperience => _hasExperience;
  bool get hasBio => _hasBio;
  bool get hasServiceType => _hasServiceType;
  bool get hasPortfolioImages => _portfolioImages.isNotEmpty;
  String? get selectedServiceType => _selectedServiceType;

  // Portfolio image management
  Future<void> addPortfolioImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Upload image to Firebase Storage and get URL
        final String imageUrl = await _uploadImageToStorage(image);
        _portfolioImages.add(imageUrl);
        notifyListeners();
        _updateProfileCompletion();
      }
    } catch (e) {
      print('Error picking image: $e');
      // You might want to show a snackbar or dialog to inform the user
    }
  }

  void removePortfolioImage(int index) {
    if (index >= 0 && index < _portfolioImages.length) {
      _portfolioImages.removeAt(index);
      notifyListeners();
      _updateProfileCompletion();
    }
  }

  Future<String> _uploadImageToStorage(XFile image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName =
          'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'skilled_workers/${user.uid}/portfolio/$fileName';

      final Reference ref = FirebaseStorage.instance.ref().child(path);
      final UploadTask uploadTask = ref.putFile(File(image.path));

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Category management
  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
    _updateProfileCompletion();
  }

  // Add custom category
  void addCustomCategory(String customCategory) {
    if (customCategory.isNotEmpty &&
        !_selectedCategories.contains(customCategory)) {
      _selectedCategories.add(customCategory);
      notifyListeners();
      _updateProfileCompletion();
    }
  }

  // Service type selection
  void selectServiceType(String? serviceType) {
    _selectedServiceType = serviceType;
    notifyListeners();
    _updateProfileCompletion();
  }

  // Update profile completion status
  void _updateProfileCompletion() {
    _hasBasicInfo = true; // Always true when this provider is used
    _hasSkills = _selectedCategories.isNotEmpty;
    _hasExperience = experienceController.text.isNotEmpty;
    _hasBio = bioController.text.isNotEmpty && bioController.text.length >= 20;
    _hasServiceType =
        _selectedServiceType != null && _selectedServiceType!.isNotEmpty;

    _isProfileComplete =
        _hasBasicInfo &&
        _hasSkills &&
        _hasExperience &&
        _hasBio &&
        _hasServiceType;
    notifyListeners();
  }

  void updateProfileCompletion() {
    _updateProfileCompletion();
  }

  // Validation
  bool get isFormValid {
    return _selectedCategories.isNotEmpty &&
        experienceController.text.isNotEmpty &&
        bioController.text.isNotEmpty &&
        bioController.text.length >= 20 &&
        _selectedServiceType != null &&
        _selectedServiceType!.isNotEmpty;
  }

  double get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 5; // Updated to include service type

    if (_hasBasicInfo) completedFields++;
    if (_hasSkills) completedFields++;
    if (_hasExperience) completedFields++;
    if (_hasBio) completedFields++;
    if (_hasServiceType) completedFields++;

    return completedFields / totalFields;
  }

  String get profileCompletionMessage {
    if (_isProfileComplete) {
      return 'Portfolio Complete! You can now request jobs.';
    } else {
      List<String> missingFields = [];
      if (!_hasSkills) missingFields.add('skills');
      if (!_hasExperience) missingFields.add('experience');
      if (!_hasBio) missingFields.add('bio');

      return 'Complete your portfolio to request jobs. Missing: ${missingFields.join(', ')}';
    }
  }

  // Clear form
  void clearForm() {
    _portfolioImages.clear();
    _selectedCategories.clear();
    experienceController.clear();
    bioController.clear();
    hourlyRateController.clear();
    availabilityController.clear();
    _resetCompletionStatus();
    notifyListeners();
  }

  // Reset completion status
  void _resetCompletionStatus() {
    _isProfileComplete = false;
    _hasBasicInfo = false;
    _hasSkills = false;
    _hasExperience = false;
    _hasBio = false;
  }

  // Mark profile as complete (for testing or admin purposes)
  void markProfileComplete() {
    _isProfileComplete = true;
    _hasBasicInfo = true;
    _hasSkills = true;
    _hasExperience = true;
    _hasBio = true;
    notifyListeners();
  }

  // Check user authentication status
  bool get isUserAuthenticated {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid.isNotEmpty;
  }

  // Get current user info for debugging
  Map<String, dynamic>? getCurrentUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'phoneNumber': user.phoneNumber,
      'displayName': user.displayName,
      'email': user.email,
      'isEmailVerified': user.emailVerified,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  // Test Firestore connection
  Future<bool> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for test');
        return false;
      }

      // Try to read from a test document
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .get();

      print('Firestore connection test successful');
      return true;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  // Test Firestore write operation
  Future<bool> testFirestoreWrite() async {
    try {
      print('Testing Firestore write operation...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for write test');
        return false;
      }

      // Try to write a test document
      await FirebaseFirestore.instance
          .collection('test')
          .doc('write_test_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            'test': true,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });

      print('Firestore write test successful');
      return true;
    } catch (e) {
      print('Firestore write test failed: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  // Comprehensive debug method to test Firebase setup
  Future<Map<String, dynamic>> debugFirebaseSetup() async {
    final debugInfo = <String, dynamic>{};

    try {
      // Check user authentication
      final user = FirebaseAuth.instance.currentUser;
      debugInfo['userAuthenticated'] = user != null;
      if (user != null) {
        debugInfo['userId'] = user.uid;
        debugInfo['userPhone'] = user.phoneNumber;
        debugInfo['userDisplayName'] = user.displayName;
      }

      // Test Firestore read
      try {
        await FirebaseFirestore.instance.collection('test').doc('debug').get();
        debugInfo['firestoreRead'] = true;
      } catch (e) {
        debugInfo['firestoreRead'] = false;
        debugInfo['firestoreReadError'] = e.toString();
      }

      // Test Firestore write
      try {
        await FirebaseFirestore.instance
            .collection('test')
            .doc('debug_write')
            .set({'test': true, 'timestamp': FieldValue.serverTimestamp()});
        debugInfo['firestoreWrite'] = true;
      } catch (e) {
        debugInfo['firestoreWrite'] = false;
        debugInfo['firestoreWriteError'] = e.toString();
      }

      // Check current data state
      debugInfo['currentData'] = {
        'skills': _selectedCategories,
        'experience': experienceController.text.trim(),
        'bio': bioController.text.trim(),
        'hourlyRate': hourlyRateController.text.trim(),
        'availability': availabilityController.text.trim(),
        'portfolioImages': _portfolioImages,
      };

      // Check validation
      debugInfo['validation'] = {
        'hasRequiredData': true, // No validation needed
        'skillsCount': _selectedCategories.length,
        'experienceLength': experienceController.text.trim().length,
        'bioLength': bioController.text.trim().length,
      };
    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    print('Debug info: $debugInfo');
    return debugInfo;
  }

  // Check validation status and show what's missing
  Map<String, dynamic> getValidationStatus() {
    final status = {
      'categories': {
        'hasData': _selectedCategories.isNotEmpty,
        'count': _selectedCategories.length,
        'data': _selectedCategories,
      },
      'experience': {
        'hasData': experienceController.text.trim().isNotEmpty,
        'length': experienceController.text.trim().length,
        'data': experienceController.text.trim(),
      },
      'bio': {
        'hasData': bioController.text.trim().isNotEmpty,
        'length': bioController.text.trim().length,
        'meetsMinLength': bioController.text.trim().length >= 20,
        'data': bioController.text.trim(),
      },
      'overall': {
        'isValid': true,
        'missingFields': <String>[],
      }, // No validation needed
    };

    // Calculate missing fields
    if (!(status['categories'] as Map<String, dynamic>)['hasData']) {
      (status['overall'] as Map<String, dynamic>)['missingFields'].add(
        'categories',
      );
    }
    if (!(status['experience'] as Map<String, dynamic>)['hasData']) {
      (status['overall'] as Map<String, dynamic>)['missingFields'].add(
        'experience',
      );
    }
    if (!(status['bio'] as Map<String, dynamic>)['hasData'] ||
        !(status['bio'] as Map<String, dynamic>)['meetsMinLength']) {
      (status['overall'] as Map<String, dynamic>)['missingFields'].add(
        'bio (min 20 chars)',
      );
    }

    return status;
  }

  // Test save method - bypasses validation to test Firebase connection
  Future<bool> testSaveToFirebase() async {
    try {
      print('🧪 TESTING FIREBASE SAVE (bypassing validation)...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      final testData = {
        'userId': user.uid,
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'This is a test save to verify Firebase connection',
      };

      print('📦 Test data: $testData');

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(user.uid)
          .set(testData, SetOptions(merge: true));

      print('✅ Test save successful! Firebase connection works.');
      return true;
    } catch (e) {
      print('❌ Test save failed: $e');
      return false;
    }
  }

  // Force save portfolio - bypasses all validation for testing
  Future<bool> forceSavePortfolio() async {
    try {
      print('Force saving portfolio...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return false;
      }

      // Save whatever data is available
      final portfolioData = {
        'userId': user.uid,
        'categories': _selectedCategories,
        'experience': experienceController.text.trim(),
        'rate': hourlyRateController.text.trim(),
        'availability': availabilityController.text.trim(),
        'description': bioController.text.trim(),
        'images': _portfolioImages,
        'forceSaved': true,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('Force saving: $portfolioData');

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(user.uid)
          .set(portfolioData, SetOptions(merge: true));

      print('Portfolio force saved!');
      return true;
    } catch (e) {
      print('Force save error: $e');
      return false;
    }
  }

  // Simple check: Does user have any portfolio data? - by phone number
  Future<bool> hasAnyPortfolioData() async {
    try {
      // Get current logged in phone number
      final user = FirebaseAuth.instance.currentUser;
      final phoneNumber = user?.phoneNumber;

      if (phoneNumber == null) {
        print('❌ No authenticated user found');
        return false;
      }

      print('🔍 Checking if phone $phoneNumber has portfolio data...');

      // Search for portfolio document by phone number - try different formats
      QuerySnapshot querySnapshot;

      // First try exact match
      querySnapshot =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .where('userPhone', isEqualTo: phoneNumber)
              .get();

      // If no exact match, try without + prefix
      if (querySnapshot.docs.isEmpty && phoneNumber.startsWith('+')) {
        final phoneWithoutPlus = phoneNumber.substring(1);
        querySnapshot =
            await FirebaseFirestore.instance
                .collection('SkilledWorkers')
                .where('userPhone', isEqualTo: phoneWithoutPlus)
                .get();
      }

      // If still no match, try with + prefix
      if (querySnapshot.docs.isEmpty && !phoneNumber.startsWith('+')) {
        final phoneWithPlus = '+$phoneNumber';
        querySnapshot =
            await FirebaseFirestore.instance
                .collection('SkilledWorkers')
                .where('userPhone', isEqualTo: phoneWithPlus)
                .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final hasData = data.isNotEmpty && data.length > 1;

        print('📄 Portfolio document exists: $hasData');
        print('📋 Document ID: ${doc.id}');
        print('📋 Fields found: ${data.keys.toList()}');
        return hasData;
      } else {
        print('❌ No portfolio document found for phone: $phoneNumber');
        return false;
      }
    } catch (e) {
      print('❌ Error checking portfolio data: $e');
      return false;
    }
  }

  // Debug: Check what's actually in the user's portfolio
  Future<void> debugPortfolioData() async {
    try {
      print('=== DEBUGGING PORTFOLIO DATA ===');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('👤 User ID: ${user.uid}');

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('📄 Portfolio document exists with fields:');

        data.forEach((key, value) {
          print('   $key: $value (type: ${value.runtimeType})');
        });

        // Check specific fields
        print('\n🔍 Specific field checks:');
        print('   Categories: ${data['categories']}');
        print('   Experience: ${data['experience']}');
        print('   Description: ${data['description']}');
        print('   Rate: ${data['rate']}');
        print('   Availability: ${data['availability']}');
        print('   Images: ${data['images']}');
      } else {
        print('❌ No portfolio document found');
      }
    } catch (e) {
      print('❌ Error debugging portfolio: $e');
    }
  }

  // Check if user can request jobs (has completed portfolio) - by phone number
  Future<bool> canRequestJobs(BuildContext context) async {
    try {
      print('=== CHECKING IF USER CAN REQUEST JOBS ===');

      // Get current logged in user from SkilledWorkerProvider
      final skilledWorkerProvider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );

      if (!skilledWorkerProvider.isLoggedIn ||
          skilledWorkerProvider.loggedInUserId == null) {
        print('❌ No authenticated skilled worker found');
        return false;
      }

      final userId = skilledWorkerProvider.loggedInUserId!;
      final phoneNumber = skilledWorkerProvider.loggedInPhoneNumber ?? '';

      print('👤 Current user ID: $userId');
      print('📱 Current phone number: $phoneNumber');

      // Get portfolio document directly by user ID
      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(userId)
              .get();

      print('🔍 Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        print('📄 Found portfolio document!');
        print('📋 Document ID: ${doc.id}');
        print('📋 Document fields: ${data.keys.toList()}');

        // Check if profile is completed
        final profileCompleted = data['profileCompleted'] == true;
        final portfolioCompleted = data['completed'] == true;
        print('✅ Profile completed: $profileCompleted');
        print('✅ Portfolio completed: $portfolioCompleted');

        if (profileCompleted || portfolioCompleted) {
          print('🎯 User can request jobs - profile/portfolio is complete!');
          return true;
        } else {
          print('⚠️ Profile/portfolio exists but not marked as completed');
          return false;
        }
      } else {
        print('❌ No portfolio document found for user ID: $userId');
        return false;
      }
    } catch (e) {
      print('❌ Error checking job request eligibility: $e');
      return false;
    }
  }

  // Get portfolio completion status for UI display
  Future<Map<String, dynamic>> getPortfolioStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'hasPortfolio': false,
          'canRequestJobs': false,
          'missingFields': ['User not authenticated'],
          'message': 'Please log in to view portfolio status',
        };
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final hasCategories =
            data['categories'] != null &&
            (data['categories'] as List).isNotEmpty;
        final hasExperience =
            data['experience'] != null &&
            data['experience'].toString().isNotEmpty;
        final hasDescription =
            data['description'] != null &&
            data['description'].toString().isNotEmpty;

        final missingFields = <String>[];
        if (!hasCategories) missingFields.add('Skills/Categories');
        if (!hasExperience) missingFields.add('Experience');
        if (!hasDescription) missingFields.add('Description');

        final canRequestJobs = hasCategories && hasExperience && hasDescription;

        return {
          'hasPortfolio': true,
          'canRequestJobs': canRequestJobs,
          'missingFields': missingFields,
          'message':
              canRequestJobs
                  ? 'Portfolio complete! You can request jobs.'
                  : 'Complete your portfolio to request jobs. Missing: ${missingFields.join(', ')}',
        };
      }

      return {
        'hasPortfolio': false,
        'canRequestJobs': false,
        'missingFields': ['Portfolio not created'],
        'message': 'Create your portfolio to start requesting jobs',
      };
    } catch (e) {
      return {
        'hasPortfolio': false,
        'canRequestJobs': false,
        'missingFields': ['Error: $e'],
        'message': 'Error checking portfolio status',
      };
    }
  }

  // Load existing portfolio data if it exists
  Future<bool> loadExistingPortfolio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('Found existing portfolio: ${data.keys.toList()}');

        // Load data into form fields
        if (data['categories'] != null) {
          _selectedCategories.clear();
          _selectedCategories.addAll(List<String>.from(data['categories']));
        }

        if (data['experience'] != null) {
          experienceController.text = data['experience'];
        }

        if (data['rate'] != null) {
          hourlyRateController.text = data['rate'];
        }

        if (data['availability'] != null) {
          availabilityController.text = data['availability'];
        }

        if (data['description'] != null) {
          bioController.text = data['description'];
        }

        if (data['images'] != null) {
          _portfolioImages.clear();
          _portfolioImages.addAll(List<String>.from(data['images']));
        }

        notifyListeners();
        print('Portfolio data loaded successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading portfolio: $e');
      return false;
    }
  }

  // Check if portfolio already exists for current user
  Future<bool> portfolioAlreadyExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Check if portfolio has the required fields
        return data['categories'] != null &&
            data['experience'] != null &&
            data['description'] != null;
      }
      return false;
    } catch (e) {
      print('Error checking portfolio: $e');
      return false;
    }
  }

  // Save portfolio to Firestore - NO VALIDATIONS, JUST SAVE
  Future<bool> savePortfolioToFirestore(
    String userId,
    String phoneNumber,
  ) async {
    try {
      print('=== SAVING PORTFOLIO TO FIREBASE ===');

      if (userId.isEmpty) {
        print('❌ No user ID provided');
        return false;
      }

      print('👤 Saving portfolio for user: $userId');
      print('📱 Phone number: $phoneNumber');
      print('📋 Selected categories: $_selectedCategories');
      print('💼 Experience: ${experienceController.text}');
      print('💰 Rate: ${hourlyRateController.text}');
      print('📝 Description: ${bioController.text}');
      print('🖼️ Images: $_portfolioImages');

      // Save portfolio data with user ID
      final portfolioData = {
        'userId': userId, // Use the logged in user ID
        'userPhone': phoneNumber, // Phone number for searching
        'categories': _selectedCategories,
        'serviceType': _selectedServiceType, // Add service type
        'experience': experienceController.text.trim(),
        'rate': hourlyRateController.text.trim(),
        'availability': availabilityController.text.trim(),
        'description': bioController.text.trim(),
        'images': _portfolioImages,
        'timestamp': FieldValue.serverTimestamp(),
        'completed': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      print('📦 Portfolio data to save: $portfolioData');

      // Save to collection using user ID as document ID
      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(userId) // Use user ID as document ID
          .set(portfolioData, SetOptions(merge: true));

      // Also update the main user document to mark profile as completed
      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(userId)
          .update({
            'profileCompleted': true,
            'portfolioCompleted': true,
            'profileCompletedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Portfolio saved successfully!');
      print('✅ Profile marked as completed!');
      print('📄 Document ID: $userId');
      print('📱 Phone number: $phoneNumber');
      print('🔗 Collection: SkilledWorkers');

      // Update local state
      _updateProfileCompletion();

      return true;
    } catch (e) {
      print('❌ Error saving portfolio: $e');
      return false;
    }
  }

  // Load existing portfolio from Firestore
  Future<bool> loadPortfolioFromFirestore(String userId) async {
    try {
      if (userId.isEmpty) {
        print('No user ID provided');
        return false;
      }

      print('Loading portfolio for user: $userId');

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(userId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('Found existing portfolio data: ${data.keys.toList()}');

        // Load skills
        if (data['categories'] != null) {
          _selectedCategories.clear();
          _selectedCategories.addAll(List<String>.from(data['categories']));
          print('Loaded skills: $_selectedCategories');
        }

        // Load service type
        if (data['serviceType'] != null) {
          _selectedServiceType = data['serviceType'];
          print('Loaded service type: $_selectedServiceType');
        }

        // Load experience
        if (data['experience'] != null) {
          experienceController.text = data['experience'];
          print('Loaded experience: ${data['experience']}');
        }

        // Load bio
        if (data['description'] != null) {
          bioController.text = data['description'];
          print('Loaded bio length: ${data['description'].toString().length}');
        }

        // Load hourly rate
        if (data['rate'] != null) {
          hourlyRateController.text = data['rate'];
          print('Loaded hourly rate: ${data['rate']}');
        }

        // Load availability
        if (data['availability'] != null) {
          availabilityController.text = data['availability'];
          print('Loaded availability: ${data['availability']}');
        }

        // Load portfolio images
        if (data['images'] != null) {
          _portfolioImages.clear();
          _portfolioImages.addAll(List<String>.from(data['images']));
          print('Loaded portfolio images: ${_portfolioImages.length}');
        }

        // Update completion status
        _updateProfileCompletion();
        notifyListeners();

        print('Skill profile loaded successfully');
        return true;
      } else {
        print('No existing portfolio found, creating new user document');
        // Create initial user document
        await _createInitialUserDocument(userId);
        return true;
      }
    } catch (e) {
      print('Error loading skill profile: $e');
      return false;
    }
  }

  // Create initial user document
  Future<void> _createInitialUserDocument(String userId) async {
    try {
      final initialData = {
        'userId': userId,
        'categories': [],
        'experience': '',
        'rate': '',
        'availability': '',
        'description': '',
        'images': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(userId)
          .set(initialData);

      print('Initial user document created successfully');
    } catch (e) {
      print('Error creating initial user document: $e');
    }
  }

  // Update specific field in portfolio
  Future<bool> updatePortfolioField(String field, dynamic value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Map old field names to new ones for backward compatibility
      String firestoreField = field;
      if (field == 'skills') firestoreField = 'categories';
      if (field == 'bio') firestoreField = 'description';
      if (field == 'hourlyRate') firestoreField = 'rate';
      if (field == 'portfolioImages') firestoreField = 'images';

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(user.uid)
          .update({
            firestoreField: value,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('Updated field $firestoreField with value: $value');
      return true;
    } catch (e) {
      print('Error updating field $field: $e');
      return false;
    }
  }

  // Get portfolio statistics
  Future<Map<String, dynamic>?> getPortfolioStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'rating': data['rating'] ?? 0.0,
          'totalJobs': data['totalJobs'] ?? 0,
          'completedJobs': data['completedJobs'] ?? 0,
          'verificationStatus': data['verificationStatus'] ?? 'pending',
          'status': data['status'] ?? 'active',
        };
      }
      return null;
    } catch (e) {
      print('Error getting portfolio stats: $e');
      return null;
    }
  }

  // Check if portfolio exists
  Future<bool> portfolioExists(String userId) async {
    try {
      if (userId.isEmpty) {
        return false;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(userId)
              .get();

      return doc.exists;
    } catch (e) {
      print('Error checking portfolio existence: $e');
      return false;
    }
  }

  // Delete portfolio (for testing or user deletion)
  Future<bool> deletePortfolio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(user.uid)
          .delete();

      // Clear local data
      clearForm();
      print('Portfolio deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting portfolio: $e');
      return false;
    }
  }

  @override
  void dispose() {
    experienceController.dispose();
    bioController.dispose();
    hourlyRateController.dispose();
    availabilityController.dispose();
    super.dispose();
  }
}
