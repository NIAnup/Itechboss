import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/security/aes_gcm_service.dart';
import '../models/user_model.dart';
import 'secure_storage_datasource.dart';

class CachedProfilePayload {
  final UserModel user;
  final DateTime cachedAt;
  final String cipherMode;

  CachedProfilePayload({
    required this.user,
    required this.cachedAt,
    required this.cipherMode,
  });

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'cachedAt': cachedAt.toIso8601String(),
        'cipherMode': cipherMode,
      };

  factory CachedProfilePayload.fromJson(Map<String, dynamic> json) {
    return CachedProfilePayload(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? '') ?? DateTime.now(),
      cipherMode: json['cipherMode'] as String? ?? 'AES-256-GCM',
    );
  }
}

class EncryptedFileDataSource {
  final AesGcmService _aesGcmService;
  final SecureStorageDataSource _secureStorage;
  static const String _cacheFileName = 'vault_profile_cache.bin';

  EncryptedFileDataSource({
    required AesGcmService aesGcmService,
    required SecureStorageDataSource secureStorage,
  })  : _aesGcmService = aesGcmService,
        _secureStorage = secureStorage;

  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_cacheFileName');
  }

  /// Encrypts and writes profile data to disk
  Future<void> writeProfileCache(UserModel user) async {
    try {
      final keyBytes = await _secureStorage.getOrCreateAesMasterKey();
      final payload = CachedProfilePayload(
        user: user,
        cachedAt: DateTime.now(),
        cipherMode: _aesGcmService.cipherModeName,
      );

      final jsonString = jsonEncode(payload.toJson());
      final encryptedBytes = await _aesGcmService.encrypt(
        plainText: jsonString,
        secretKeyBytes: keyBytes,
      );

      final file = await _getCacheFile();
      await file.writeAsBytes(encryptedBytes, flush: true);
    } catch (e) {
      // Ignore write errors or bubble up if needed
    }
  }

  /// Reads and decrypts profile cache from disk.
  /// Returns null if file doesn't exist, is corrupted, or fails authentication tag (cache miss).
  Future<CachedProfilePayload?> readProfileCache() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) {
        return null;
      }

      final encryptedBytes = await file.readAsBytes();
      if (encryptedBytes.isEmpty) {
        return null;
      }

      final keyBytes = await _secureStorage.getOrCreateAesMasterKey();
      final decryptedJson = await _aesGcmService.decrypt(
        encryptedData: encryptedBytes,
        secretKeyBytes: keyBytes,
      );

      if (decryptedJson == null) {
        // Cache miss / auth tag failure
        return null;
      }

      final jsonMap = jsonDecode(decryptedJson) as Map<String, dynamic>;
      return CachedProfilePayload.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Deletes the encrypted cache file on logout
  Future<void> deleteProfileCache() async {
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
