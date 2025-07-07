import 'package:shared_preferences/shared_preferences.dart';

class CallHistoryHelper {
  static Future<void> addCallHistory(
    String number,
    String type,
    String status,
  ) async {
    final now = DateTime.now();
    final entry = {
      'number': number,
      'type': type,
      'status': status,
      'time': now.toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    // prefs.clear(); // Clear previous history for testing purposes
    final history = prefs.getStringList('callHistory') ?? [];
    history.insert(0, entry.toString());
    await prefs.setStringList('callHistory', history.take(100).toList());
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  static Future<List<Map<String, dynamic>>> loadCallHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('callHistory') ?? [];
    return history
        .map((e) {
          try {
            final entry = _parseMapString(e);
            if (entry['time'] != null &&
                DateTime.tryParse(entry['time']) != null) {
              entry['timeAgo'] = formatTimeAgo(DateTime.parse(entry['time']));
            } else {
              entry['time'] = DateTime.now().toIso8601String();
              entry['timeAgo'] = 'just now';
            }
            return entry;
          } catch (_) {
            return {};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  static Map<String, dynamic> _parseMapString(String s) {
    s = s.replaceAll(RegExp(r'[{}]'), '');
    final map = <String, dynamic>{};
    for (final part in s.split(',')) {
      final kv = part.split(':');
      if (kv.length == 2) {
        map[kv[0].trim()] = kv[1].trim();
      }
    }
    return map;
  }
}
