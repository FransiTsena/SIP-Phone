import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ContactApi {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getContacts({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/contacts?page=$page&limit=$limit',
    );
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load contacts (${res.statusCode})');
  }

  static Future<Map<String, dynamic>> createContact(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('${AppConfig.baseUrl}/api/contacts');
    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create contact (${res.statusCode}) ${res.body}');
  }

  static Future<Map<String, dynamic>> updateContact(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('${AppConfig.baseUrl}/api/contacts/$id');
    final res = await http.put(
      uri,
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update contact (${res.statusCode})');
  }

  static Future<void> deleteContact(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('${AppConfig.baseUrl}/api/contacts/$id');
    final res = await http.delete(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete contact (${res.statusCode})');
    }
  }

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
