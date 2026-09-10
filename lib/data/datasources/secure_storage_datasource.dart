import 'dart:convert';
import 'dart:typed_data';
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
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // Tokens
  Future<void> saveTokens(AuthTokensModel tokens) async {
    await _storage.write(key: _keyAccessToken, value: tokens.accessToken);
    await _storage.write(key: _keyRefreshToken, value: tokens.refreshToken);
  }

  Future<AuthTokensModel?> getTokens() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  // AES 256 Master Key for Profile Cache
  Future<Uint8List> getOrCreateAesMasterKey() async {
    final existingBase64 = await _storage.read(key: _keyAesMasterKey);
    if (existingBase64 != null && existingBase64.isNotEmpty) {
      try {
        return Uint8List.fromList(base64Decode(existingBase64));
      } catch (_) {
        // Fallthrough to regenerate if corrupted
      }
    }

    final newKey = AesGcmService.generateRandom256BitKey();
    await _storage.write(
      key: _keyAesMasterKey,
      value: base64Encode(newKey),
    );
    return newKey;
  }

  Future<void> clearAesMasterKey() async {
    await _storage.delete(key: _keyAesMasterKey);
  }

  // PIN Hash & Salt
  Future<void> savePinData({
    required Uint8List salt,
    required Uint8List hash,
  }) async {
    await _storage.write(key: _keyPinSalt, value: base64Encode(salt));
    await _storage.write(key: _keyPinHash, value: base64Encode(hash));
    await resetPinFailedAttempts();
  }

  Future<Uint8List?> getPinSalt() async {
    final saltBase64 = await _storage.read(key: _keyPinSalt);
    if (saltBase64 == null || saltBase64.isEmpty) return null;
    return Uint8List.fromList(base64Decode(saltBase64));
  }

  Future<Uint8List?> getPinHash() async {
    final hashBase64 = await _storage.read(key: _keyPinHash);
    if (hashBase64 == null || hashBase64.isEmpty) return null;
    return Uint8List.fromList(base64Decode(hashBase64));
  }

  Future<bool> hasPinSet() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyPinHash);
    await resetPinFailedAttempts();
  }

  // PIN Failed Attempts Counter
  Future<int> getPinFailedAttempts() async {
    final countStr = await _storage.read(key: _keyPinFailedAttempts);
    return int.tryParse(countStr ?? '0') ?? 0;
  }

  Future<int> incrementPinFailedAttempts() async {
    final current = await getPinFailedAttempts();
    final updated = current + 1;
    await _storage.write(
      key: _keyPinFailedAttempts,
      value: updated.toString(),
    );
    return updated;
  }

  Future<void> resetPinFailedAttempts() async {
    await _storage.delete(key: _keyPinFailedAttempts);
  }

  // Complete Secret Wipe
  Future<void> wipeAllSecrets() async {
    await _storage.deleteAll();
  }
}
