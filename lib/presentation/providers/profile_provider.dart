import 'dart:io';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  File? profileImage;

  void setProfileImage(File? image) {
    profileImage = image;
    notifyListeners();
  }
}
