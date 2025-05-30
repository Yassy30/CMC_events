import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../db/SupabaseConfig.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
      await SupabaseConfig.client.storage
          .from('eventimages')
          .uploadBinary(fileName, await image.readAsBytes(), fileOptions: const FileOptions(contentType: 'image/png'));

      final imageUrl = SupabaseConfig.client.storage.from('eventimages').getPublicUrl(fileName);
      print('Uploaded image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image from gallery: $e');
      rethrow;
    }
  }

  Future<String?> generateAndUploadImage(String prompt, String apiToken) async {
    try {
      final url = Uri.parse('https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-2-1');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': prompt}),
      );

      if (response.statusCode == 200) {
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
        await SupabaseConfig.client.storage
            .from('event_images')
            .uploadBinary(fileName, response.bodyBytes, fileOptions: const FileOptions(contentType: 'image/png'));

        final imageUrl = SupabaseConfig.client.storage.from('event_images').getPublicUrl(fileName);
        print('Generated and uploaded image URL: $imageUrl');
        return imageUrl;
      } else {
        print('Image generation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error generating and uploading image: $e');
      rethrow;
    }
  }
}