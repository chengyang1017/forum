import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, midnight }

class AppThemeCubit extends Cubit<AppThemeMode> {
  AppThemeCubit() : super(AppThemeMode.light) {
    _loadSavedTheme();
  }

  static const String _preferenceKey = 'appThemeMode';

  bool get isMidnight => state == AppThemeMode.midnight;

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_preferenceKey);

    if (savedMode == AppThemeMode.midnight.name) {
      emit(AppThemeMode.midnight);
    }
  }

  Future<void> setMidnight(bool enabled) async {
    final nextMode = enabled ? AppThemeMode.midnight : AppThemeMode.light;

    if (state != nextMode) {
      emit(nextMode);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, nextMode.name);
  }
}
