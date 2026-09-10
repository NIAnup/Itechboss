import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class AesGcmService {
  static const int keyLengthBytes = 32; // 256 bits
  static const int nonceLengthBytes = 12; // 96 bits nonce
  static const int tagLengthBits = 128; // 128 bits tag (16 bytes)

  /// Generates a random 256-bit (32 bytes) master encryption key.
  static Uint8List generateRandom256BitKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(keyLengthBytes);
    for (int i = 0; i < keyLengthBytes; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return keyBytes;
  }

  /// Encrypts plaintext JSON string using AES-256-GCM.
  /// Generates a fresh 12-byte random nonce for EVERY single write.
  /// Output format: [12 bytes nonce] + [ciphertext with 16 bytes tag]
  Future<Uint8List> encrypt({
    required String plainText,
    required Uint8List secretKeyBytes,
  }) async {
    final clearTextBytes = Uint8List.fromList(utf8.encode(plainText));

    // Fresh 12-byte nonce (96 bits) per encryption
    final random = Random.secure();
    final nonce = Uint8List(nonceLengthBytes);
    for (int i = 0; i < nonceLengthBytes; i++) {
      nonce[i] = random.nextInt(256);
    }

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(secretKeyBytes),
      tagLengthBits,
      nonce,
      Uint8List(0),
    );
    cipher.init(true, params);

    final cipherTextWithTag = cipher.process(clearTextBytes);

    // Concatenate: Nonce (12 bytes) + CipherText with Tag
    final result = Uint8List(nonce.length + cipherTextWithTag.length);
    result.setRange(0, nonce.length, nonce);
    result.setRange(nonce.length, result.length, cipherTextWithTag);

    return result;
  }

  /// Decrypts encrypted bytes using AES-256-GCM and verifies the authentication tag.
  /// Returns decrypted plaintext String, or null if decryption / tag verification fails (cache miss).
  Future<String?> decrypt({
    required Uint8List encryptedData,
    required Uint8List secretKeyBytes,
  }) async {
    try {
      // Minimum length: 12 (nonce) + 16 (tag) = 28 bytes
      if (encryptedData.length < (nonceLengthBytes + (tagLengthBits ~/ 8))) {
        return null;
      }

      final nonce = encryptedData.sublist(0, nonceLengthBytes);
      final cipherTextWithTag = encryptedData.sublist(nonceLengthBytes);

      final decipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(secretKeyBytes),
        tagLengthBits,
        nonce,
        Uint8List(0),
      );
      decipher.init(false, params);

      final decryptedBytes = decipher.process(cipherTextWithTag);
      return utf8.decode(decryptedBytes);
    } catch (_) {
      // Authentication tag mismatch or corrupted ciphertext -> Cache Miss (§4.1 / §5)
      return null;
    }
  }

  /// Constant metadata descriptor
  String get cipherModeName => 'AES-256-GCM';
}
