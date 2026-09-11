import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/security/aes_gcm_service.dart';
import 'core/security/pin_hasher.dart';
import 'core/security/root_jailbreak_service.dart';
import 'core/security/screen_privacy_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/encrypted_file_datasource.dart';
import 'data/datasources/preferences_datasource.dart';
import 'data/datasources/secure_storage_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/pin_repository_impl.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/pin_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'presentation/viewmodels/auth/login_cubit.dart';
import 'presentation/viewmodels/pin/pin_cubit.dart';
import 'presentation/viewmodels/pin/pin_state.dart';
import 'presentation/viewmodels/profile/profile_cubit.dart';
import 'presentation/viewmodels/settings/settings_cubit.dart';
import 'presentation/viewmodels/splash/splash_cubit.dart';
import 'presentation/viewmodels/theme/theme_cubit.dart';
import 'presentation/views/auth/login_screen.dart';
import 'presentation/views/intro/intro_screen.dart';
import 'presentation/views/pin/pin_lock_screen.dart';
import 'presentation/views/pin/set_pin_screen.dart';
import 'presentation/views/profile/profile_screen.dart';
import 'presentation/views/security/device_compromised_screen.dart';
import 'presentation/views/settings/settings_screen.dart';
import 'presentation/views/splash/splash_screen.dart';
import 'presentation/widgets/app_lifecycle_pin_barrier.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Core Services
  final aesGcmService = AesGcmService();
  final pinHasher = PinHasher();
  final rootJailbreakService = RootJailbreakService();
  final screenPrivacyService = ScreenPrivacyService();

  // Data Sources
  final secureStorage = SecureStorageDataSource();
  final preferences = await PreferencesDataSource.create();
  final encryptedCache = EncryptedFileDataSource(
    aesGcmService: aesGcmService,
    secureStorage: secureStorage,
  );

  final authRemoteDataSource = AuthRemoteDataSource(
    secureStorage: secureStorage,
    onSessionExpired: () {
      // Force navigation to login on failed refresh or expired session
      rootNavigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    },
  );

  // Repositories
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    secureStorage: secureStorage,
    preferences: preferences,
    encryptedCache: encryptedCache,
  );

  final profileRepository = ProfileRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    encryptedCache: encryptedCache,
    aesGcmService: aesGcmService,
  );

  final pinRepository = PinRepositoryImpl(
    secureStorage: secureStorage,
    encryptedCache: encryptedCache,
    pinHasher: pinHasher,
  );

  runApp(
    VaultApp(
      secureStorage: secureStorage,
      preferences: preferences,
      encryptedCache: encryptedCache,
      rootJailbreakService: rootJailbreakService,
      screenPrivacyService: screenPrivacyService,
      authRepository: authRepository,
      profileRepository: profileRepository,
      pinRepository: pinRepository,
    ),
  );
}

class VaultApp extends StatelessWidget {
  final SecureStorageDataSource secureStorage;
  final PreferencesDataSource preferences;
  final EncryptedFileDataSource encryptedCache;
  final RootJailbreakService rootJailbreakService;
  final ScreenPrivacyService screenPrivacyService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PinRepository pinRepository;

  const VaultApp({
    super.key,
    required this.secureStorage,
    required this.preferences,
    required this.encryptedCache,
    required this.rootJailbreakService,
    required this.screenPrivacyService,
    required this.authRepository,
    required this.profileRepository,
    required this.pinRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorageDataSource>.value(value: secureStorage),
        RepositoryProvider<PreferencesDataSource>.value(value: preferences),
        RepositoryProvider<EncryptedFileDataSource>.value(value: encryptedCache),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<PinRepository>.value(value: pinRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(preferences),
          ),
          BlocProvider<SplashCubit>(
            create: (_) => SplashCubit(
              secureStorage: secureStorage,
              preferences: preferences,
              rootJailbreakService: rootJailbreakService,
              screenPrivacyService: screenPrivacyService,
            ),
          ),
          BlocProvider<LoginCubit>(
            create: (_) => LoginCubit(authRepository),
          ),
          BlocProvider<ProfileCubit>(
            create: (_) => ProfileCubit(profileRepository),
          ),
          BlocProvider<PinCubit>(
            create: (_) => PinCubit(pinRepository),
          ),
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(
              pinRepository: pinRepository,
              authRepository: authRepository,
              encryptedCache: encryptedCache,
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'VAULT',
              navigatorKey: rootNavigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              initialRoute: '/',
              builder: (context, child) {
                return AppLifecyclePinBarrier(
                  child: child ?? const SizedBox.shrink(),
                );
              },
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/':
                    return MaterialPageRoute(builder: (_) => const SplashScreen());
                  case '/intro':
                    return MaterialPageRoute(builder: (_) => const IntroScreen());
                  case '/login':
                    return MaterialPageRoute(builder: (_) => const LoginScreen());
                  case '/profile':
                    return MaterialPageRoute(builder: (_) => const ProfileScreen());
                  case '/settings':
                    return MaterialPageRoute(builder: (_) => const SettingsScreen());
                  case '/set_pin':
                    final flowMode = (settings.arguments as PinFlowMode?) ?? PinFlowMode.create;
                    return MaterialPageRoute(
                      builder: (_) => SetPinScreen(flowMode: flowMode),
                    );
                  case '/pin_lock':
                    return MaterialPageRoute(
                      builder: (ctx) => BlocProvider<PinCubit>(
                        create: (c) => PinCubit(c.read<PinRepository>()),
                        child: const PinLockScreen(),
                      ),
                    );
                  case '/compromised':
                    return MaterialPageRoute(builder: (_) => const DeviceCompromisedScreen());
                  default:
                    return MaterialPageRoute(builder: (_) => const SplashScreen());
                }
              },
            );
          },
        ),
      ),
    );
  }
}
