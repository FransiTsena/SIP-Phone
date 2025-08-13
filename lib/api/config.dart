import 'package:shared_preferences/shared_preferences.dart';

/// Central configuration with runtime-updatable SIP server IP.
class AppConfig {
  static const String _ipKey = 'server_ip';
  static String _ip = '10.42.0.1'; // default fallback
  static int port = 8088;

  static String get ip => _ip;
  static String get baseUrl => 'http://$_ip:4000';
  static String get webSocketUrl => 'ws://$_ip:8088/ws';

  /// Load saved IP from preferences (call early, e.g. in main before runApp if needed).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ip = prefs.getString(_ipKey) ?? _ip;
  }

  /// Persist and update in-memory IP.
  static Future<void> setIp(String newIp) async {
    _ip = newIp.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, _ip);
  }
}
