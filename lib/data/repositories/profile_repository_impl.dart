import '../../core/security/aes_gcm_service.dart';
import '../../core/utils/error_formatter.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/encrypted_file_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final EncryptedFileDataSource _encryptedCache;
  final AesGcmService _aesGcmService;

  ProfileRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required EncryptedFileDataSource encryptedCache,
    required AesGcmService aesGcmService,
  })  : _remoteDataSource = remoteDataSource,
        _encryptedCache = encryptedCache,
        _aesGcmService = aesGcmService;

  @override
  Future<ProfileResult> getProfile({bool forceRefresh = false}) async {
    try {
      // Attempt remote fetch
      final user = await _remoteDataSource.getMe();

      // Write encrypted cache to disk immediately on successful fetch (§4.1)
      await _encryptedCache.writeProfileCache(user);

      return ProfileResult(
        user: user,
        isOffline: false,
        cachedAt: DateTime.now(),
        cipherMode: _aesGcmService.cipherModeName,
      );
    } catch (networkError) {
      // On network failure: attempt to decrypt local cache (§5)
      final cachedPayload = await _encryptedCache.readProfileCache();
      if (cachedPayload != null) {
        return ProfileResult(
          user: cachedPayload.user,
          isOffline: true,
          cachedAt: cachedPayload.cachedAt,
          cipherMode: cachedPayload.cipherMode,
        );
      }

      // No cache or corrupted cache: throw friendly error
      throw ErrorFormatter.format(networkError);
    }
  }

  @override
  Future<ProfileResult?> getCachedProfile() async {
    final cachedPayload = await _encryptedCache.readProfileCache();
    if (cachedPayload != null) {
      return ProfileResult(
        user: cachedPayload.user,
        isOffline: true,
        cachedAt: cachedPayload.cachedAt,
        cipherMode: cachedPayload.cipherMode,
      );
    }
    return null;
  }
}
