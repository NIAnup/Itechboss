import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vault_app/core/constants/api_endpoints.dart';
import 'package:vault_app/core/security/aes_gcm_service.dart';
import 'package:vault_app/core/security/pin_hasher.dart';
import 'package:vault_app/data/datasources/secure_storage_datasource.dart';
import 'package:vault_app/data/interceptors/auth_interceptor.dart';
import 'package:vault_app/data/models/auth_tokens_model.dart';

class MockSecureStorageDataSource extends Mock implements SecureStorageDataSource {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AuthTokensModel(accessToken: 'dummy', refreshToken: 'dummy'),
    );
    registerFallbackValue(RequestOptions(path: '/dummy'));
  });

  group('VAULT Security & Cryptography Unit Tests', () {
    test(
      '(1) AES round-trip plus proof that two encryptions of the same input differ',
      () async {
        final aesService = AesGcmService();
        final keyBytes = AesGcmService.generateRandom256BitKey();
        const testPayload = '{"id":1,"email":"emily.johnson@x.dummyjson.com","name":"Emily"}';

        final ciphertext1 = await aesService.encrypt(
          plainText: testPayload,
          secretKeyBytes: keyBytes,
        );

        final ciphertext2 = await aesService.encrypt(
          plainText: testPayload,
          secretKeyBytes: keyBytes,
        );

        expect(
          ciphertext1,
          isNot(equals(ciphertext2)),
          reason: 'Encrypting the same payload twice must produce two different byte arrays due to unique nonces',
        );

        final decrypted1 = await aesService.decrypt(
          encryptedData: ciphertext1,
          secretKeyBytes: keyBytes,
        );
        expect(decrypted1, equals(testPayload));

        final decrypted2 = await aesService.decrypt(
          encryptedData: ciphertext2,
          secretKeyBytes: keyBytes,
        );
        expect(decrypted2, equals(testPayload));

        final tamperedBytes = Uint8List.fromList(ciphertext1);
        tamperedBytes[tamperedBytes.length - 1] ^= 0xFF;
        final tamperedResult = await aesService.decrypt(
          encryptedData: tamperedBytes,
          secretKeyBytes: keyBytes,
        );
        expect(tamperedResult, isNull, reason: 'Tampered ciphertext must fail tag validation gracefully');
      },
    );

    test(
      '(2) PIN verification — right passes, wrong fails, stored value is not the PIN',
      () async {
        final pinHasher = PinHasher();
        final salt = PinHasher.generateRandomSalt();
        const correctPin = '739281';
        const wrongPin = '123456';

        final derivedHash = await pinHasher.hashPin(pin: correctPin, salt: salt);
        expect(derivedHash, isNot(equals(utf8.encode(correctPin))));

        final bareSha256 = crypto.sha256.convert(utf8.encode(correctPin)).bytes;
        expect(derivedHash, isNot(equals(bareSha256)));

        final isCorrectValid = await pinHasher.verifyPin(
          pin: correctPin,
          storedSalt: salt,
          storedHash: derivedHash,
        );
        expect(isCorrectValid, isTrue, reason: 'Correct PIN must pass verification');

        final isWrongValid = await pinHasher.verifyPin(
          pin: wrongPin,
          storedSalt: salt,
          storedHash: derivedHash,
        );
        expect(isWrongValid, isFalse, reason: 'Incorrect PIN must fail verification');
      },
    );

    test(
      '(3) one 401 causes exactly one refresh and one retry, mocked',
      () async {
        String currentAccessToken = 'old_access_token';
        final mockStorage = MockSecureStorageDataSource();
        when(() => mockStorage.getAccessToken()).thenAnswer((_) async => currentAccessToken);
        when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => 'valid_refresh_token');
        when(() => mockStorage.saveTokens(any())).thenAnswer((invocation) async {
          final tokens = invocation.positionalArguments[0] as AuthTokensModel;
          currentAccessToken = tokens.accessToken;
        });

        final mockAdapter = MockHttpClientAdapter();
        final dio = Dio();
        dio.httpClientAdapter = mockAdapter;

        int refreshCallCount = 0;
        int meCallCount = 0;

        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
          final options = invocation.positionalArguments[0] as RequestOptions;

          if (options.path.contains(ApiEndpoints.refresh)) {
            refreshCallCount++;
            // Simulate async network latency during refresh
            await Future.delayed(const Duration(milliseconds: 40));
            final responseJson = jsonEncode({
              'accessToken': 'new_refreshed_access_token',
              'refreshToken': 'new_refreshed_refresh_token',
            });
            return ResponseBody.fromString(
              responseJson,
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          } else if (options.path.contains(ApiEndpoints.me)) {
            meCallCount++;
            final authHeader = options.headers['Authorization'] as String?;
            if (authHeader == 'Bearer new_refreshed_access_token') {
              final responseJson = jsonEncode({
                'id': 1,
                'username': 'emilys',
                'email': 'emily.johnson@x.dummyjson.com',
                'firstName': 'Emily',
                'lastName': 'Johnson',
                'gender': 'female',
                'image': '',
              });
              return ResponseBody.fromString(
                responseJson,
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            } else {
              // Return 401 Unauthorized for expired token
              return ResponseBody.fromString(
                jsonEncode({'message': 'Token expired'}),
                401,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
          }

          return ResponseBody.fromString('{}', 404);
        });

        dio.interceptors.clear();
        dio.interceptors.add(
          AuthInterceptor(
            dio: dio,
            secureStorage: mockStorage,
          ),
        );

        // Fire 3 simultaneous concurrent calls to /auth/me
        final futures = [
          dio.get(ApiEndpoints.me),
          dio.get(ApiEndpoints.me),
          dio.get(ApiEndpoints.me),
        ];

        final responses = await Future.wait(futures);

        // Assert all 3 requests were retried and succeeded with 200
        for (final res in responses) {
          expect(res.statusCode, equals(200));
          expect((res.data as Map)['username'], equals('emilys'));
        }

        // Single-flight constraint: exactly 1 refresh call was made across all 3 concurrent 401s
        expect(
          refreshCallCount,
          equals(1),
          reason: 'Single-flight is required: exactly one refresh call must be made for concurrent 401s',
        );

        // Total 6 calls to /auth/me: 3 initial calls returning 401 + 3 retry calls returning 200
        expect(meCallCount, equals(6));
      },
    );
  });
}
