class ApiEndpoints {
  static const String baseUrl = 'https://dummyjson.com';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Default expiration time as strictly required by take-home assignment
  static const int expiresInMins = 1;
}
