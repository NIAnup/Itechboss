import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/security/root_jailbreak_service.dart';
import '../../../core/security/screen_privacy_service.dart';
import '../../../data/datasources/preferences_datasource.dart';
import '../../../data/datasources/secure_storage_datasource.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final SecureStorageDataSource _secureStorage;
  final PreferencesDataSource _preferences;
  final RootJailbreakService _rootJailbreakService;
  final ScreenPrivacyService _screenPrivacyService;

  SplashCubit({
    required SecureStorageDataSource secureStorage,
    required PreferencesDataSource preferences,
    required RootJailbreakService rootJailbreakService,
    required ScreenPrivacyService screenPrivacyService,
  })  : _secureStorage = secureStorage,
        _preferences = preferences,
        _rootJailbreakService = rootJailbreakService,
        _screenPrivacyService = screenPrivacyService,
        super(const SplashState());

  Future<void> initializeApp() async {
    // 1. Enable screenshot and screen recording privacy protection
    await _screenPrivacyService.enableProtection();

    // 2. Perform Root / Jailbreak check
    final isCompromised = await _rootJailbreakService.isDeviceCompromised();
    if (isCompromised) {
      emit(const SplashState(target: SplashTarget.deviceCompromised));
      return;
    }

    // 3. Ensure a minimum smooth splash experience without exceeding 1.5s
    final startTime = DateTime.now();

    final tokens = await _secureStorage.getTokens();
    final hasToken = tokens != null && tokens.accessToken.isNotEmpty;
    final isIntroSeen = _preferences.isIntroSeen();
    final hasPin = await _secureStorage.hasPinSet();

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 900) {
      await Future.delayed(Duration(milliseconds: 900 - elapsed));
    }

    // Routing Decision Matrix (§1):
    // No token, Intro never seen -> Intro
    // No token, Intro already seen -> Login
    // Token present, PIN set -> PIN Lock
    // Token present, no PIN -> Profile
    if (!hasToken) {
      if (!isIntroSeen) {
        emit(const SplashState(target: SplashTarget.intro));
      } else {
        emit(const SplashState(target: SplashTarget.login));
      }
    } else {
      if (hasPin) {
        emit(const SplashState(target: SplashTarget.pinLock));
      } else {
        emit(const SplashState(target: SplashTarget.profile));
      }
    }
  }
}
