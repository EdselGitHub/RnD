import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static Future<String?> uploadKartuIdentitas(XFile imageFile) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('kartu_identitas/$fileName');
      
      final bytes = await imageFile.readAsBytes();
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      await uploadTask;
      final String fullPath = ref.fullPath;
      
      return fullPath; // Berhasil upload, kembalikan path
    } catch (e) {
      print('Error uploading to Firebase Storage: $e');
      return null;
    }
  }
}

