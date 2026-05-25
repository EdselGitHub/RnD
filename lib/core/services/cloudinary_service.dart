import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';



class CloudinaryService {
  static Future<String?> uploadImage(File imageFile) async {
    String cloudName = 'dpk62tzkz';
    String uploadPreset = 'kartu_identitas';

    var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    request.fields['upload_preset'] = uploadPreset;

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        return jsonResponse['secure_url'];
      } else {
        print('gagal upload: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error pada: $e');
      return null;
    }

}
}