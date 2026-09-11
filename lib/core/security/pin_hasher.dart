import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class PinHasher {
  static const int saltLength = 16; // 16 bytes random salt
  static const int iterations = 100000; // >= 100,000 iterations
  static const int keyLength = 32; // 256-bit hash (32 bytes)

  /// Generates a cryptographically secure 16-byte random salt
  static Uint8List generateRandomSalt() {
    final random = Random.secure();
    final salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Hashes a 6-digit PIN using PBKDF2-HMAC-SHA256 with 100,000 iterations in a worker isolate
  Future<Uint8List> hashPin({
    required String pin,
    required Uint8List salt,
  }) async {
    return Isolate.run(() {
      final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2')
        ..init(Pbkdf2Parameters(salt, iterations, keyLength));

      final pinBytes = Uint8List.fromList(utf8.encode(pin));
      final derivedKey = derivator.process(pinBytes);

      return Uint8List.fromList(derivedKey);
    });
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
