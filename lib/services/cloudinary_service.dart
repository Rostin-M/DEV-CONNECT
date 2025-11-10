import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  Future<Map<String, String>> uploadScreenshot(File file) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'dev_connect/screenshots',
        ),
      );

      if (response.secureUrl.isEmpty || response.publicId.isEmpty) {
        throw Exception(
          'Error en la respuesta de Cloudinary: URL o PublicID vacíos.',
        );
      }

      return {'url': response.secureUrl, 'publicId': response.publicId};
    } on CloudinaryException catch (e) {
      throw Exception('Error al subir la imagen: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al subir la imagen.');
    }
  }

  Future<Map<String, String>> uploadProfileImage(
    File file, {
    String folder = 'dev_connect/profiles',
  }) async {
    try {
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('La imagen debe ser menor a 5MB');
      }

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );

      if (response.secureUrl.isEmpty || response.publicId.isEmpty) {
        throw Exception(
          'Error en la respuesta de Cloudinary: URL o PublicID vacíos.',
        );
      }

      return {'url': response.secureUrl, 'publicId': response.publicId};
    } on CloudinaryException catch (e) {
      throw Exception('Error al subir la imagen: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al subir la imagen: $e');
    }
  }

  Future<void> deleteImage(String publicId) async {
    try {
      // Nota: cloudinary_public no soporta eliminación directa
      // La eliminación debe hacerse desde el backend o dashboard de Cloudinary
      debugPrint('Intento de eliminar imagen con publicId: $publicId');
      // Por ahora, solo registramos el intento
    } catch (e) {
      throw Exception('Error al intentar eliminar la imagen: $e');
    }
  }
}
