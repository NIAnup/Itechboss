import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/secure_storage_datasource.dart';
import '../models/auth_tokens_model.dart';

typedef SessionExpiredCallback = void Function();

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageDataSource secureStorage;
  final SessionExpiredCallback? onSessionExpired;

  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required this.dio,
    required this.secureStorage,
    this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublicEndpoint = options.path.contains(ApiEndpoints.login) ||
        options.path.contains(ApiEndpoints.refresh);

    if (!isPublicEndpoint) {
      final token = await secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains(ApiEndpoints.refresh);
    final isLoginEndpoint = err.requestOptions.path.contains(ApiEndpoints.login);
    final isRetry = err.requestOptions.extra['isRetry'] == true;

    if (!is401 || isRefreshEndpoint || isLoginEndpoint || isRetry) {
      return handler.next(err);
    }

    // Single-Flight Mechanism (§4.3)
    if (_refreshCompleter == null) {
      final completer = Completer<String?>();
      _refreshCompleter = completer;

      try {
        final currentRefreshToken = await secureStorage.getRefreshToken();
        if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
          completer.complete(null);
          _refreshCompleter = null;
          onSessionExpired?.call();
          return handler.next(err);
        }

        // Dedicated refresh request
        final refreshResponse = await dio.post(
          ApiEndpoints.refresh,
          data: {
            'refreshToken': currentRefreshToken,
            'expiresInMins': ApiEndpoints.expiresInMins,
          },
          options: Options(
            extra: {'isRetry': true},
            headers: {'Content-Type': 'application/json'},
          ),
        );

        if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
          final newTokens = AuthTokensModel.fromJson(
            refreshResponse.data as Map<String, dynamic>,
          );
          await secureStorage.saveTokens(newTokens);

          final newAccessToken = newTokens.accessToken;
          completer.complete(newAccessToken);

          // Retry the original request
          final retryResponse = await _retryRequest(err.requestOptions, newAccessToken);
          scheduleMicrotask(() => _refreshCompleter = null);
          return handler.resolve(retryResponse);
        } else {
          completer.complete(null);
          scheduleMicrotask(() => _refreshCompleter = null);
          onSessionExpired?.call();
          return handler.next(err);
        }
      } catch (refreshError) {
        completer.complete(null);
        scheduleMicrotask(() => _refreshCompleter = null);
        onSessionExpired?.call();
        return handler.next(err);
      }
    } else {
      // Concurrently queued requests wait for the in-flight refresh to complete
      final newAccessToken = await _refreshCompleter!.future;
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        try {
          final retryResponse = await _retryRequest(err.requestOptions, newAccessToken);
          return handler.resolve(retryResponse);
        } catch (retryError) {
          if (retryError is DioException) {
            return handler.next(retryError);
          }
          return handler.next(err);
        }
      } else {
        return handler.next(err);
      }
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final newHeaders = Map<String, dynamic>.from(requestOptions.headers);
    newHeaders['Authorization'] = 'Bearer $newAccessToken';

    final newExtra = Map<String, dynamic>.from(requestOptions.extra);
    newExtra['isRetry'] = true;

    final options = Options(
      method: requestOptions.method,
      headers: newHeaders,
      extra: newExtra,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
