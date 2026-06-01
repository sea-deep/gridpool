import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  static String get _baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
  }

  /// Pick an image from gallery or camera
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('ImageUploadService.pickImage error: $e');
      return null;
    }
  }

  /// Show a bottom sheet to choose camera or gallery, then pick image
  static Future<File?> pickImageWithSource() async {
    // Default to gallery — the UI can provide source selection
    return pickImage(source: ImageSource.gallery);
  }

  /// Upload an image file to the backend (which forwards to Cloudinary)
  /// Returns the Cloudinary URL on success, null on failure
  static Future<String?> uploadImage(
    File imageFile, {
    String folder = 'gridpool',
  }) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }

      final token = await user.getIdToken();
      final uri = Uri.parse('$_baseUrl/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['folder'] = folder
        final ext = imageFile.path.split('.').last.toLowerCase();
        final mimeSubtype = const {
          'jpg': 'jpeg', 'jpeg': 'jpeg', 'png': 'png',
          'gif': 'gif', 'webp': 'webp', 'heic': 'heic',
        }[ext] ?? 'jpeg';

        ..files.add(
          await http.MultipartFile.fromPath(
            'image', 
            imageFile.path,
            contentType: MediaType('image', mimeSubtype),
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] as String?;
        debugPrint('ImageUploadService: Upload successful → $url');
        return url;
      } else {
        debugPrint('ImageUploadService: Upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ImageUploadService.uploadImage error: $e');
      return null;
    }
  }

  /// Convenience: pick from gallery and upload in one step
  static Future<String?> pickAndUpload({
    ImageSource source = ImageSource.gallery,
    String folder = 'gridpool',
  }) async {
    final file = await pickImage(source: source);
    if (file == null) return null;
    return uploadImage(file, folder: folder);
  }
}
