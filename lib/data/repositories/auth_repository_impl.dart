import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/encrypted_file_datasource.dart';
import '../datasources/preferences_datasource.dart';
import '../datasources/secure_storage_datasource.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageDataSource _secureStorage;
  final PreferencesDataSource _preferences;
  final EncryptedFileDataSource _encryptedCache;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageDataSource secureStorage,
    required PreferencesDataSource preferences,
    required EncryptedFileDataSource encryptedCache,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _preferences = preferences,
        _encryptedCache = encryptedCache;

  @override
  Future<({AuthTokensModel tokens, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      username: username,
      password: password,
    );

    // Save tokens in hardware-backed secure storage
    await _secureStorage.saveTokens(result.tokens);

    // Write AES-256-GCM encrypted cache on disk
    await _encryptedCache.writeProfileCache(result.user);

    return result;
  }

  @override
  Future<bool> isAuthenticated() async {
    final tokens = await _secureStorage.getTokens();
    return tokens != null && tokens.accessToken.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    // Clear tokens, AES master key, PIN salt, PIN hash, and failed attempts
    await _secureStorage.wipeAllSecrets();

    // Delete encrypted cache file
    await _encryptedCache.deleteProfileCache();
  }

  @override
  Future<bool> isIntroSeen() async {
    return _preferences.isIntroSeen();
  }

  @override
  Future<void> setIntroSeen(bool seen) async {
    await _preferences.setIntroSeen(seen);
  }
}
