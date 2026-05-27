import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String?> uploadKartuIdentitas(File imageFile) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('kartu_identitas/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading to Firebase Storage: $e');
      return null;
    }
  }
}
