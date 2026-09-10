import '../../data/models/user_model.dart';

class ProfileResult {
  final UserModel user;
  final bool isOffline;
  final DateTime cachedAt;
  final String cipherMode;

  ProfileResult({
    required this.user,
    required this.isOffline,
    required this.cachedAt,
    required this.cipherMode,
  });
}

abstract class ProfileRepository {
  Future<ProfileResult> getProfile({bool forceRefresh = false});
  Future<ProfileResult?> getCachedProfile();
}
