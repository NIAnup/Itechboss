import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../interceptors/auth_interceptor.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';
import 'secure_storage_datasource.dart';

class AuthRemoteDataSource {
  late final Dio _dio;
  final SecureStorageDataSource _secureStorage;
  final SessionExpiredCallback? onSessionExpired;

  AuthRemoteDataSource({
    required SecureStorageDataSource secureStorage,
    this.onSessionExpired,
    Dio? customDio,
  }) : _secureStorage = secureStorage {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

    // Attach single-flight interceptor
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        secureStorage: _secureStorage,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  Dio get dio => _dio;

  /// POST /auth/login with { username, password, expiresInMins: 1 }
  Future<({AuthTokensModel tokens, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
        'expiresInMins': ApiEndpoints.expiresInMins,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final tokens = AuthTokensModel.fromJson(data);
    final user = UserModel.fromJson(data);

    return (tokens: tokens, user: user);
  }

  /// GET /auth/me with Bearer token injected by interceptor
  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// POST /auth/refresh with { refreshToken, expiresInMins: 1 }
  Future<AuthTokensModel> refresh({required String refreshToken}) async {
    final response = await _dio.post(
      ApiEndpoints.refresh,
      data: {
        'refreshToken': refreshToken,
        'expiresInMins': ApiEndpoints.expiresInMins,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return AuthTokensModel.fromJson(data);
  }
}
