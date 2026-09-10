import '../../data/models/auth_tokens_model.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<({AuthTokensModel tokens, UserModel user})> login({
    required String username,
    required String password,
  });

  Future<bool> isAuthenticated();

  Future<void> logout();

  Future<bool> isIntroSeen();

  Future<void> setIntroSeen(bool seen);
}
