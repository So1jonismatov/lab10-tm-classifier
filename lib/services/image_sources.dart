import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageSourceException implements Exception {
  const ImageSourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

// null = user cancelled
class ImageSources {
  final _picker = ImagePicker();

  Future<Uint8List?> fromCamera() => _pick(ImageSource.camera);

  Future<Uint8List?> fromGallery() => _pick(ImageSource.gallery);

  Future<Uint8List?> _pick(ImageSource source) async {
    try {
      final shot = await _picker.pickImage(source: source, maxWidth: 1024);
      return shot == null ? null : await shot.readAsBytes();
    } catch (_) {
      throw ImageSourceException(
        source == ImageSource.camera
            ? 'The camera is not available. Check the camera permission.'
            : 'The photo library is not available. Check the photos permission.',
      );
    }
  }

  Future<Uint8List> fromUrl(String url, {Duration timeout = const Duration(seconds: 15)}) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')) || uri.host.isEmpty) {
      throw const ImageSourceException('That is not a valid web address. Start with https://');
    }
    final http.Response response;
    try {
      response = await http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ImageSourceException('The download took too long. Try again or use another link.');
    } on SocketException {
      throw const ImageSourceException('No network connection or unknown address.');
    } on http.ClientException {
      throw const ImageSourceException('The download failed. Check the address and your connection.');
    }
    if (response.statusCode != 200) {
      throw ImageSourceException('The server answered ${response.statusCode}, not 200.');
    }
    final type = response.headers['content-type'] ?? '';
    if (!type.startsWith('image/')) {
      throw ImageSourceException(
        'That address is not a picture (content-type: ${type.isEmpty ? 'missing' : type}).',
      );
    }
    return response.bodyBytes;
  }
}
