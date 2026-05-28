import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'admin_firebase_auth.dart';
import 'admin_storage.dart';

class StoredImageFile {
  const StoredImageFile({
    required this.path,
    required this.name,
    required this.downloadUrl,
  });

  final String path;
  final String name;
  final String downloadUrl;
}

/// Admin panelde görsel seçip Firebase Storage'a yükler.
class AdminImageUploadService {
  AdminImageUploadService._();

  static final AdminImageUploadService instance = AdminImageUploadService._();

  static const int maxUploadBytes = 5 * 1024 * 1024;
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const Duration urlTimeout = Duration(seconds: 20);

  /// Storage erişim testi (Medya sekmesi / durum çubuğu).
  Future<String> probeAccess() async {
    await AdminFirebaseAuth.trySignIn();
    try {
      await adminStorage.ref('items').list(const ListOptions(maxResults: 1)).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('Storage yanıt vermedi'),
      );
      return 'Storage bağlantısı OK';
    } on FirebaseException catch (e) {
      return _friendlyStorageError(e);
    } catch (e) {
      return e.toString();
    }
  }

  /// Kullanıcıdan bir görsel seçer ve belirtilen klasöre yükler.
  Future<String?> pickAndUploadImage({
    required String folder,
    required String entityId,
  }) async {
    final authed = await AdminFirebaseAuth.trySignIn();
    if (!authed) {
      debugPrint(
        'Admin: anonim giriş yok — açık Storage kurallarıyla yükleme deneniyor.',
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      throw StateError(
        'Dosya okunamadı. Chrome/Safari deneyin; dosya 5 MB altında olsun.',
      );
    }
    if (bytes.length > maxUploadBytes) {
      throw StateError(
        'Dosya çok büyük (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB). '
        'En fazla ${maxUploadBytes ~/ (1024 * 1024)} MB.',
      );
    }

    final rawExt = file.extension ?? '';
    final ext = rawExt.isEmpty ? 'png' : rawExt.toLowerCase();
    final sanitizedId =
        entityId.trim().isEmpty ? 'item' : entityId.trim().replaceAll(' ', '_');
    final fileName =
        '${sanitizedId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final ref = adminStorage.ref().child('$folder/$fileName');
    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(ext),
    );

    try {
      final task = ref.putData(bytes, metadata);
      final snapshot = await task.timeout(
        uploadTimeout,
        onTimeout: () => throw TimeoutException(_setupHint),
      );
      if (snapshot.state != TaskState.success) {
        throw StateError('Yükleme tamamlanamadı: ${snapshot.state}');
      }
      return await ref.getDownloadURL().timeout(
        urlTimeout,
        onTimeout: () => throw TimeoutException(
          'Dosya yüklendi ama indirme URL’si alınamadı.',
        ),
      );
    } on FirebaseException catch (e) {
      throw StateError(_friendlyStorageError(e));
    }
  }

  Future<List<StoredImageFile>> listImages(String folder) async {
    await AdminFirebaseAuth.trySignIn();
    final root = adminStorage.ref(folder);
    final result = await root.listAll().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('Medya listesi zaman aşımı.'),
    );
    final entries = <StoredImageFile>[];
    for (final ref in result.items) {
      final url = await ref.getDownloadURL().timeout(urlTimeout);
      entries.add(
        StoredImageFile(
          path: ref.fullPath,
          name: ref.name,
          downloadUrl: url,
        ),
      );
    }
    entries.sort((a, b) => b.name.compareTo(a.name));
    return entries;
  }

  Future<void> deleteImageByPath(String fullPath) async {
    await AdminFirebaseAuth.trySignIn();
    await adminStorage.ref(fullPath).delete().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Silme zaman aşımı.'),
    );
  }

  static const _setupHint =
      'Storage yanıt vermiyor.\n'
      '1) console.firebase.google.com → questalarm → Storage → Get started\n'
      '2) Rules sekmesine projedeki storage.rules içeriğini yapıştırın\n'
      '3) Publish';

  String _contentTypeForExtension(String ext) {
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      _ => 'image/png',
    };
  }

  String _friendlyStorageError(FirebaseException e) {
    final code = e.code.toLowerCase();
    final message = e.message ?? '';
    if (code.contains('unauthorized') ||
        code.contains('permission') ||
        code.contains('unauthenticated')) {
      return 'Storage izni reddedildi ($code).\n'
          'Console → Storage → Rules → items/ ve maps/ için write: true\n'
          'veya Anonymous Auth açın.\n$message';
    }
    if (code.contains('not-found') || message.contains('does not exist')) {
      return 'Storage bucket yok veya kapalı.\n'
          'Console → questalarm → Storage → Get started ile oluşturun.\n'
          '($code)';
    }
    if (code.contains('canceled')) {
      return 'Yükleme iptal edildi.';
    }
    if (code.contains('retry-limit')) {
      return 'Ağ hatası — bağlantınızı kontrol edip tekrar deneyin.';
    }
    return 'Storage ($code): ${message.isEmpty ? _setupHint : message}';
  }
}
