import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/encrypted_file_datasource.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/pin_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final PinRepository _pinRepository;
  final AuthRepository _authRepository;
  final EncryptedFileDataSource _encryptedCache;

  SettingsCubit({
    required PinRepository pinRepository,
    required AuthRepository authRepository,
    required EncryptedFileDataSource encryptedCache,
  })  : _pinRepository = pinRepository,
        _authRepository = authRepository,
        _encryptedCache = encryptedCache,
        super(const SettingsState());

  Future<void> loadSettings() async {
    final hasPin = await _pinRepository.isPinSet();
    final cached = await _encryptedCache.readProfileCache();
    final username = cached?.user.username ?? 'emilys';

    emit(state.copyWith(
      isPinSet: hasPin,
      username: username,
      isLoggedOut: false,
    ));
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(state.copyWith(isLoggedOut: true));
  }
}
