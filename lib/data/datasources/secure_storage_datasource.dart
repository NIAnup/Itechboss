import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/security/aes_gcm_service.dart';
import '../models/auth_tokens_model.dart';

class SecureStorageDataSource {
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'vault_access_token';
  static const String _keyRefreshToken = 'vault_refresh_token';
  static const String _keyAesMasterKey = 'vault_aes_master_key';
  static const String _keyPinSalt = 'vault_pin_salt';
  static const String _keyPinHash = 'vault_pin_hash';
  static const String _keyPinFailedAttempts = 'vault_pin_failed_attempts';

  SecureStorageDataSource({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // Tokens
  Future<void> saveTokens(AuthTokensModel tokens) async {
    try {
      await _storage.write(key: _keyAccessToken, value: tokens.accessToken);
      await _storage.write(key: _keyRefreshToken, value: tokens.refreshToken);
    } catch (e) {
      debugPrint('Secure storage saveTokens error: $e');
    }
  }

  Future<AuthTokensModel?> getTokens() async {
    try {
      final accessToken = await _storage.read(key: _keyAccessToken);
      final refreshToken = await _storage.read(key: _keyRefreshToken);
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
      return AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
    } catch (e) {
      debugPrint('Secure storage getTokens error: $e');
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      debugPrint('Secure storage getAccessToken error: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('Secure storage getRefreshToken error: $e');
      return null;
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('Secure storage clearTokens error: $e');
    }
  }

  // AES 256 Master Key for Profile Cache
  Future<Uint8List> getOrCreateAesMasterKey() async {
    try {
      final existingBase64 = await _storage.read(key: _keyAesMasterKey);
      if (existingBase64 != null && existingBase64.isNotEmpty) {
        try {
          return Uint8List.fromList(base64Decode(existingBase64));
        } catch (_) {}
      }

      final newKey = AesGcmService.generateRandom256BitKey();
      await _storage.write(
        key: _keyAesMasterKey,
        value: base64Encode(newKey),
      );
      return newKey;
    } catch (e) {
      debugPrint('Secure storage master key error: $e');
      return AesGcmService.generateRandom256BitKey();
    }
  }

  Future<void> clearAesMasterKey() async {
    try {
      await _storage.delete(key: _keyAesMasterKey);
    } catch (e) {
      debugPrint('Secure storage clearAesMasterKey error: $e');
    }
  }

  // PIN Hash & Salt
  Future<void> savePinData({
    required Uint8List salt,
    required Uint8List hash,
  }) async {
    try {
      await _storage.write(key: _keyPinSalt, value: base64Encode(salt));
      await _storage.write(key: _keyPinHash, value: base64Encode(hash));
      await resetPinFailedAttempts();
    } catch (e) {
      debugPrint('Secure storage savePinData error: $e');
    }
  }

  Future<Uint8List?> getPinSalt() async {
    try {
      final saltBase64 = await _storage.read(key: _keyPinSalt);
      if (saltBase64 == null || saltBase64.isEmpty) return null;
      return Uint8List.fromList(base64Decode(saltBase64));
    } catch (e) {
      debugPrint('Secure storage getPinSalt error: $e');
      return null;
    }
  }

  Future<Uint8List?> getPinHash() async {
    try {
      final hashBase64 = await _storage.read(key: _keyPinHash);
      if (hashBase64 == null || hashBase64.isEmpty) return null;
      return Uint8List.fromList(base64Decode(hashBase64));
    } catch (e) {
      debugPrint('Secure storage getPinHash error: $e');
      return null;
    }
  }

  Future<bool> hasPinSet() async {
    try {
      final hash = await _storage.read(key: _keyPinHash);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      debugPrint('Secure storage hasPinSet error: $e');
      return false;
    }
  }

  Future<void> clearPin() async {
    try {
      await _storage.delete(key: _keyPinSalt);
      await _storage.delete(key: _keyPinHash);
      await resetPinFailedAttempts();
    } catch (e) {
      debugPrint('Secure storage clearPin error: $e');
    }
  }

  // PIN Failed Attempts Counter
  Future<int> getPinFailedAttempts() async {
    try {
      final countStr = await _storage.read(key: _keyPinFailedAttempts);
      return int.tryParse(countStr ?? '0') ?? 0;
    } catch (e) {
      debugPrint('Secure storage getPinFailedAttempts error: $e');
      return 0;
    }
  }

  Future<int> incrementPinFailedAttempts() async {
    try {
      final current = await getPinFailedAttempts();
      final updated = current + 1;
      await _storage.write(
        key: _keyPinFailedAttempts,
        value: updated.toString(),
      );
      return updated;
    } catch (e) {
      debugPrint('Secure storage incrementPinFailedAttempts error: $e');
      return 1;
    }
  }

  Future<void> resetPinFailedAttempts() async {
    try {
      await _storage.delete(key: _keyPinFailedAttempts);
    } catch (e) {
      debugPrint('Secure storage resetPinFailedAttempts error: $e');
    }
  }

  // Complete Secret Wipe
  Future<void> wipeAllSecrets() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Secure storage wipeAllSecrets error: $e');
    }
  }
}
