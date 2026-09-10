import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/preferences_datasource.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final PreferencesDataSource _preferences;

  ThemeCubit(this._preferences) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = _preferences.getThemeMode();
    switch (mode) {
      case AppThemeModePreference.light:
        emit(ThemeMode.light);
        break;
      case AppThemeModePreference.dark:
        emit(ThemeMode.dark);
        break;
      case AppThemeModePreference.system:
        emit(ThemeMode.system);
        break;
    }
  }

  Future<void> setTheme(AppThemeModePreference mode) async {
    await _preferences.setThemeMode(mode);
    switch (mode) {
      case AppThemeModePreference.light:
        emit(ThemeMode.light);
        break;
      case AppThemeModePreference.dark:
        emit(ThemeMode.dark);
        break;
      case AppThemeModePreference.system:
        emit(ThemeMode.system);
        break;
    }
  }

  AppThemeModePreference get currentPreference => _preferences.getThemeMode();
}
