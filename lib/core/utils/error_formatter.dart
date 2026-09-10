import 'package:dio/dio.dart';

class ErrorFormatter {
  static String format(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data is Map && data.containsKey('message')) {
          return data['message'].toString();
        }

        switch (statusCode) {
          case 400:
            return 'Invalid credentials or request data.';
          case 401:
            return 'Invalid username or password.';
          case 403:
            return 'Access forbidden.';
          case 404:
            return 'Requested resource not found.';
          case 500:
          case 502:
          case 503:
            return 'Server error. Please try again later.';
          default:
            return 'Network request failed (${statusCode ?? "unknown"}).';
        }
      } else {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return 'Connection timed out. Check your internet connection.';
        } else if (error.type == DioExceptionType.connectionError) {
          return 'No internet connection detected.';
        }
        return 'Network error occurred. Please check your connection.';
      }
    }

    if (error is String) {
      return error;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
