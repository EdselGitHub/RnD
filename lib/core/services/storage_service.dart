import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static Future<String?> uploadKartuIdentitas(XFile imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('kartu_identitas/$fileName');
      
      final bytes = await imageFile.readAsBytes();
      final UploadTask uploadTask = ref.putData( //upload bytes ke firestore
        bytes,
        SettableMetadata(contentType: 'image/jpeg'), // tandai sebagai image/jpeg
      );
      
      await uploadTask;
      final String fullPath = ref.fullPath; // ambil path lengkap di storage
      
      return fullPath; // berhasil upload, kembalikan path
    } catch (e) {
      debugPrint('Error upload ke firebase storage: $e');
      return null;
    }
  }
}
