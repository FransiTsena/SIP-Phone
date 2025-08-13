import 'dart:convert';

import 'package:fe/api/config.dart';
import 'package:http/http.dart' as http;

class Agents {
  static Future<Map<String, dynamic>> getByNumber(String number) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/agent/$number');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load agent');
    }
  }
}
