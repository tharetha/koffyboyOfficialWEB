import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();

  factory FirebaseStorageService() {
    return _instance;
  }

  FirebaseStorageService._internal();

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String?> uploadFile(File file, String folderPath) async {
    try {
      final fileName = basename(file.path);
      final destination = '$folderPath/$fileName';
      final ref = FirebaseStorage.instance.ref(destination);
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file to Firebase: $e');
      return null;
    }
  }
}
