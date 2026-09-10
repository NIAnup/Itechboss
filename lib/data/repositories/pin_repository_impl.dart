import '../../core/security/pin_hasher.dart';
import '../../domain/repositories/pin_repository.dart';
import '../datasources/encrypted_file_datasource.dart';
import '../datasources/secure_storage_datasource.dart';

class PinRepositoryImpl implements PinRepository {
  final SecureStorageDataSource _secureStorage;
  final EncryptedFileDataSource _encryptedCache;
  final PinHasher _pinHasher;

  static const int maxAttempts = 3;

  PinRepositoryImpl({
    required SecureStorageDataSource secureStorage,
    required EncryptedFileDataSource encryptedCache,
    required PinHasher pinHasher,
  })  : _secureStorage = secureStorage,
        _encryptedCache = encryptedCache,
        _pinHasher = pinHasher;

  @override
  Future<bool> isPinSet() async {
    return _secureStorage.hasPinSet();
  }

  @override
  Future<void> savePin(String pin) async {
    final salt = PinHasher.generateRandomSalt();
    final hash = await _pinHasher.hashPin(pin: pin, salt: salt);
    await _secureStorage.savePinData(salt: salt, hash: hash);
  }

  @override
  Future<PinVerificationResult> verifyPin(String pin) async {
    final salt = await _secureStorage.getPinSalt();
    final hash = await _secureStorage.getPinHash();

    if (salt == null || hash == null) {
      return PinVerificationResult.incorrect;
    }

    final isValid = await _pinHasher.verifyPin(
      pin: pin,
      storedSalt: salt,
      storedHash: hash,
    );

    if (isValid) {
      await _secureStorage.resetPinFailedAttempts();
      return PinVerificationResult.success;
    } else {
      final attempts = await _secureStorage.incrementPinFailedAttempts();
      if (attempts >= maxAttempts) {
        // 3rd consecutive failed attempt -> wipe all secrets and force logout (§4.2)
        await _secureStorage.wipeAllSecrets();
        await _encryptedCache.deleteProfileCache();
        return PinVerificationResult.lockedOut;
      }
      return PinVerificationResult.incorrect;
    }
  }

  @override
  Future<int> getRemainingAttempts() async {
    final failed = await _secureStorage.getPinFailedAttempts();
    final remaining = maxAttempts - failed;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Future<void> clearPin() async {
    await _secureStorage.clearPin();
  }

  @override
  Future<void> resetAttempts() async {
    await _secureStorage.resetPinFailedAttempts();
  }
}
