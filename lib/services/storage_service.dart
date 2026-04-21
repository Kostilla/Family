import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase.dart';

class StorageService {
  static const bucket = 'family-files';
  final _uuid = const Uuid();

  Future<String> uploadBytes({
    required String familyId,
    required Uint8List bytes,
    required String originalName,
  }) async {
    final ext = p.extension(originalName);
    final path = '$familyId/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}$ext';
    final mime = lookupMimeType(originalName, headerBytes: bytes);

    await sb.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mime ?? 'application/octet-stream',
            upsert: false,
          ),
        );

    return path;
  }

  Future<String> signedUrl(String path, {int expiresIn = 3600}) {
    return sb.storage.from(bucket).createSignedUrl(path, expiresIn);
  }
}
