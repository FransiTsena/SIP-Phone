import 'dart:io';
import 'package:fe/screens/call_detail_page.dart';
import 'package:fe/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CallHistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> callHistory;
  const CallHistoryPage({super.key, required this.callHistory});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  String _searchQuery = '';
  String _sortCriteria = 'date';

  // Helper: get the original index from the master list for an item in a filtered/sorted list
  int _originalIndexOf(Map<String, dynamic> call) {
    return widget.callHistory.indexOf(call);
  }

  Future<void> _exportCallHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/call_history.csv';
      final file = File(filePath);

      final csvData = widget.callHistory
          .map((call) {
            return '${call['number']},${call['type']},${call['status']},${call['time']},${call['duration'] ?? ''}';
          })
          .join('\n');

      await file.writeAsString('Number,Type,Status,Time,Duration\n$csvData');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call history exported to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export call history')),
      );
    }
  }

  void _deleteCall(int index) {
    setState(() {
      widget.callHistory.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Call deleted successfully')));
  }

  void _clearCallHistory() {
    setState(() {
      widget.callHistory.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Call history cleared')));
  }

  void _toggleFavorite(int index) {
    setState(() {
      widget.callHistory[index]['isFavorite'] =
          !(widget.callHistory[index]['isFavorite'] ?? false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.callHistory[index]['isFavorite']
              ? 'Added to favorites'
              : 'Removed from favorites',
        ),
      ),
    );
  }

  // Safer wrappers when we only know the reference (from filtered/sorted lists)
  void _deleteCallByRef(Map<String, dynamic> call) {
    final idx = _originalIndexOf(call);
    if (idx >= 0) {
      _deleteCall(idx);
    }
  }

  void _toggleFavoriteByRef(Map<String, dynamic> call) {
    final idx = _originalIndexOf(call);
    if (idx >= 0) {
      _toggleFavorite(idx);
    }
  }

  Widget _buildCallStatistics() {
    int totalCalls = widget.callHistory.length;
    int missedCalls = widget.callHistory
        .where((call) => call['type'] == 'missed')
        .length;
    int outgoingCalls = widget.callHistory
        .where((call) => call['type'] == 'outgoing')
        .length;
    int incomingCalls = widget.callHistory
        .where((call) => call['type'] == 'incoming')
        .length;

    final scheme = Theme.of(context).colorScheme;
    final cardColor = scheme.surface;
    final border = BorderSide(color: scheme.outlineVariant, width: 1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildStatisticTile('Total', totalCalls, Icons.call)),
          Expanded(
            child: _buildStatisticTile(
              'Missed',
              missedCalls,
              Icons.call_missed_outgoing,
            ),
          ),
          Expanded(
            child: _buildStatisticTile(
              'Outgoing',
              outgoingCalls,
              Icons.call_made_outlined,
            ),
          ),
          Expanded(
            child: _buildStatisticTile(
              'Incoming',
              incomingCalls,
              Icons.call_received_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticTile(
    String label,
    int count,
    IconData icon, {
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = color ?? scheme.onSurfaceVariant;
    final textColor = scheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredHistory = widget.callHistory.where((
      call,
    ) {
      return call['number']?.contains(_searchQuery) ?? false;
    }).toList();

    filteredHistory.sort((a, b) {
      switch (_sortCriteria) {
        case 'date':
          final ad =
              DateTime.tryParse((a['time'] ?? '') as String) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd =
              DateTime.tryParse((b['time'] ?? '') as String) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad); // newest first
        case 'type':
          return (a['type'] ?? '').compareTo(b['type'] ?? '');
        case 'duration':
          return (b['duration'] ?? 0).compareTo(a['duration'] ?? 0);
        default:
          return 0;
      }
    });

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (v) {
              switch (v) {
                case 'export':
                  _exportCallHistory();
                  break;
                case 'clear':
                  _clearCallHistory();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text('Export CSV')),
              PopupMenuItem(value: 'clear', child: Text('Clear all')),
            ],
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCallStatistics(),
            const SizedBox(height: 12),
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by number',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: scheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _searchQuery = ''),
                      ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 8),
            // Sorting chips
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Date'),
                  selected: _sortCriteria == 'date',
                  onSelected: (_) => setState(() => _sortCriteria = 'date'),
                ),
                ChoiceChip(
                  label: const Text('Type'),
                  selected: _sortCriteria == 'type',
                  onSelected: (_) => setState(() => _sortCriteria = 'type'),
                ),
                ChoiceChip(
                  label: const Text('Duration'),
                  selected: _sortCriteria == 'duration',
                  onSelected: (_) => setState(() => _sortCriteria = 'duration'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant, width: 1),
                ),
                child: filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_toggle_off,
                              size: 40,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No call history',
                              style: TextStyle(
                                fontSize: 16,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calls you make and receive will appear here.',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredHistory.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: scheme.outlineVariant.withOpacity(.6),
                        ),
                        itemBuilder: (context, i) {
                          final call = filteredHistory[i];
                          // Robust time display: prefer ISO -> format; else timeAgo; else raw string
                          String timeAgo;
                          final rawTime = call['time'];
                          DateTime? dt;
                          if (rawTime is String) {
                            dt = DateTime.tryParse(rawTime);
                          }
                          if (dt != null) {
                            timeAgo = formatTimeAgo(dt);
                          } else if (call['timeAgo'] is String &&
                              (call['timeAgo'] as String).isNotEmpty) {
                            timeAgo = call['timeAgo'] as String;
                          } else if (rawTime is String && rawTime.isNotEmpty) {
                            timeAgo = rawTime; // may be already relative text
                          } else {
                            timeAgo = 'Just now';
                          }
                          final callType = (call['type'] ?? '').toString();

                          IconData icon;
                          switch (callType) {
                            case 'outgoing':
                              icon = Icons.north_east_rounded;
                              break;
                            case 'incoming':
                              icon = Icons.south_west_rounded;
                              break;
                            case 'missed':
                              icon = Icons.call_missed_outgoing_rounded;
                              break;
                            default:
                              icon = Icons.call_outlined;
                          }

                          final isFav = (call['isFavorite'] ?? false) as bool;

                          Color dotColor;
                          switch (callType) {
                            case 'outgoing':
                              dotColor = scheme.primary.withOpacity(.6);
                              break;
                            case 'incoming':
                              dotColor = scheme.tertiary.withOpacity(.6);
                              break;
                            case 'missed':
                              dotColor = Colors.redAccent.withOpacity(.7);
                              break;
                            default:
                              dotColor = scheme.onSurfaceVariant;
                          }

                          final leftBg = Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: scheme.surfaceContainerHighest.withOpacity(
                              .6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav
                                      ? Colors.redAccent
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Favorite',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );

                          final rightBg = Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red.withOpacity(.08),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          );

                          return Dismissible(
                            key: ValueKey(call.hashCode ^ i),
                            background: leftBg,
                            secondaryBackground: rightBg,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                _toggleFavoriteByRef(call);
                                return false; // Keep item; we only toggled
                              } else {
                                _deleteCallByRef(call);
                                return true; // Remove from list visually
                              }
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (call['number'] ?? '') as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${call['status'] ?? 'Unknown'} • $timeAgo',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: isFav ? 'Unfavorite' : 'Favorite',
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav
                                          ? Colors.redAccent
                                          : scheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => _toggleFavoriteByRef(call),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteCallByRef(call),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CallDetailPage(callDetails: call),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
