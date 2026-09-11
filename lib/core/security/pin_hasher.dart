import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto_pkg;

class PinHasher {
  static const int saltLength = 16; // 16 bytes random salt
  static const int iterations = 100000; // >= 100,000 iterations
  static const int keyLength = 32; // 256-bit hash (32 bytes)

  final crypto_pkg.Pbkdf2 _pbkdf2 = crypto_pkg.Pbkdf2(
    macAlgorithm: crypto_pkg.Hmac.sha256(),
    iterations: iterations,
    bits: keyLength * 8,
  );

  /// Generates a cryptographically secure 16-byte random salt
  static Uint8List generateRandomSalt() {
    final random = Random.secure();
    final salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Hashes a 6-digit PIN using PBKDF2-HMAC-SHA256 with 100,000 iterations
  Future<Uint8List> hashPin({
    required String pin,
    required Uint8List salt,
  }) async {
    final secretKey = crypto_pkg.SecretKey(utf8.encode(pin));
    final newSecretKey = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    final bytes = await newSecretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Verifies a PIN against stored salt and hash in constant time
  Future<bool> verifyPin({
    required String pin,
    required Uint8List storedSalt,
    required Uint8List storedHash,
  }) async {
    final candidateHash = await hashPin(pin: pin, salt: storedSalt);
    return constantTimeEquals(candidateHash, storedHash);
  }

  /// Constant-time comparison to prevent timing attacks
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
