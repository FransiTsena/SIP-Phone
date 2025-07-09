import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    final history = prefs.getStringList('callHistory') ?? [];
    // Use JSON encoding for each entry
    history.insert(0, jsonEncode(entry));
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

  /// Loads call history and adds a 'timeAgo' field for UI display.
  /// Optionally sorts and filters the result.
  static Future<List<Map<String, dynamic>>> loadCallHistory({
    String sortType = 'newest',
    String? filterType, // e.g. 'missed', 'answered', etc.
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('callHistory') ?? [];
    List<Map<String, dynamic>> parsed = history
        .map((e) {
          try {
            final entry = _parseMapString(e);
            if (entry['time'] != null &&
                DateTime.tryParse(entry['time']) != null) {
              entry['time'] = formatTimeAgo(DateTime.parse(entry['time']));
            } else {
              entry['time'] = DateTime.now().toIso8601String();
            }
            return entry;
          } catch (_) {
            return {};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList()
        .cast<Map<String, dynamic>>();

    // Optional filtering
    if (filterType != null && filterType.isNotEmpty) {
      parsed = parsed
          .where(
            (e) =>
                (e['status'] ?? '').toLowerCase() == filterType.toLowerCase(),
          )
          .toList();
    }

    // Sorting
    parsed = sortCallHistory(parsed, sortType);
    return parsed;
  }

  /// Sorts call history by the given type: 'newest', 'oldest', 'missed', 'answered'.
  static List<Map<String, dynamic>> sortCallHistory(
    List<Map<String, dynamic>> history,
    String sortType,
  ) {
    List<Map<String, dynamic>> sorted = List.from(history);
    switch (sortType) {
      case 'oldest':
        sorted.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
        break;
      case 'missed':
        sorted.sort(
          (a, b) =>
              (b['status'] == 'missed' ? 1 : 0) -
              (a['status'] == 'missed' ? 1 : 0),
        );
        break;
      case 'answered':
        sorted.sort(
          (a, b) =>
              (b['status'] == 'answered' ? 1 : 0) -
              (a['status'] == 'answered' ? 1 : 0),
        );
        break;
      case 'newest':
      default:
        sorted.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
        break;
    }
    return sorted;
  }

  static Map<String, dynamic> _parseMapString(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
