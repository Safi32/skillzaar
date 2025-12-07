import 'package:flutter/material.dart';
import 'dart:io';

class CnicProvider with ChangeNotifier {
  File? _frontImage;
  File? _backImage;

  // Getters
  File? get frontImage => _frontImage;
  File? get backImage => _backImage;

  // Image management
  void setFrontImage(File? image) {
    _frontImage = image;
    notifyListeners();
  }

  void setBackImage(File? image) {
    _backImage = image;
    notifyListeners();
  }

  // Validation
  bool get isFormValid {
    return _frontImage != null && _backImage != null;
  }

  // Clear images
  void clearImages() {
    _frontImage = null;
    _backImage = null;
    notifyListeners();
  }
}
