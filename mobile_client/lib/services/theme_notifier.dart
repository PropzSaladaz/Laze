import 'package:flutter/material.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/core/themes/app_theme.dart';

enum AppThemeOption {
  system,
  light,
  dark,
  black;

  String get label => switch (this) {
        AppThemeOption.system => 'System',
        AppThemeOption.light => 'Light',
        AppThemeOption.dark => 'Dark',
        AppThemeOption.black => 'Black',
      };
}

class ThemeNotifier extends ChangeNotifier {
  final DeviceSettingsRepository _settings;
  AppThemeOption _option;

  ThemeNotifier(this._settings, AppThemeOption initial) : _option = initial;

  AppThemeOption get option => _option;

  ThemeMode get themeMode => switch (_option) {
        AppThemeOption.system => ThemeMode.system,
        AppThemeOption.light => ThemeMode.light,
        AppThemeOption.dark => ThemeMode.dark,
        AppThemeOption.black => ThemeMode.dark,
      };

  /// When black is selected, the darkTheme slot carries the black palette.
  ThemeData get darkTheme =>
      _option == AppThemeOption.black ? AppTheme.black : AppTheme.dark;

  Future<void> setOption(AppThemeOption option) async {
    if (_option == option) return;
    _option = option;
    notifyListeners();
    await _settings.setThemeOption(option.name);
  }

  static Future<ThemeNotifier> create(
      DeviceSettingsRepository settings) async {
    final saved = await settings.getThemeOption();
    final initial = AppThemeOption.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => AppThemeOption.system,
    );
    return ThemeNotifier(settings, initial);
  }
}
