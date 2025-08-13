import 'package:shared_preferences/shared_preferences.dart';

class CallUiPrefs {
  static const _kAutoMinimizeOnConnect = 'auto_minimize_on_connect';
  static const _kUseChipCompactUi = 'use_chip_compact_ui';

  static Future<bool> getAutoMinimizeOnConnect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoMinimizeOnConnect) ?? false;
  }

  static Future<void> setAutoMinimizeOnConnect(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoMinimizeOnConnect, v);
  }

  static Future<bool> getUseChipCompactUi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseChipCompactUi) ?? true;
  }

  static Future<void> setUseChipCompactUi(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseChipCompactUi, v);
  }
}
