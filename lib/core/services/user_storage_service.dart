import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UserStorageService {
  static Future<String> uploadUserImage({
    required String userId,
    required File file,
    required String pathSegment,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(userId)
        .child(pathSegment)
        .child(DateTime.now().millisecondsSinceEpoch.toString());

    final uploadTask = await storageRef.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
