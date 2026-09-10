import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeModePreference { light, dark, system }

class PreferencesDataSource {
  static const String _keyIntroSeen = 'vault_intro_seen';
  static const String _keyThemeMode = 'vault_theme_mode';

  final SharedPreferences _prefs;

  PreferencesDataSource(this._prefs);

  static Future<PreferencesDataSource> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesDataSource(prefs);
  }

  // Intro Seen Flag
  bool isIntroSeen() {
    return _prefs.getBool(_keyIntroSeen) ?? false;
  }

  Future<void> setIntroSeen(bool seen) async {
    await _prefs.setBool(_keyIntroSeen, seen);
  }

  // Theme Mode
  AppThemeModePreference getThemeMode() {
    final modeStr = _prefs.getString(_keyThemeMode);
    switch (modeStr) {
      case 'dark':
        return AppThemeModePreference.dark;
      case 'light':
        return AppThemeModePreference.light;
      case 'system':
      default:
        return AppThemeModePreference.system;
    }
  }

  Future<void> setThemeMode(AppThemeModePreference mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keyIntroSeen);
    await _prefs.remove(_keyThemeMode);
  }
}
