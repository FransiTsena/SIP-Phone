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

  Future<String> _getContactName(String phoneNumber) async {
    // Simulate contact lookup (replace with actual API or database integration)
    Map<String, String> contacts = {
      '1234567890': 'Test Contact 1',
      '0987654321': 'Test Contact 2',
    };
    return contacts[phoneNumber] ?? phoneNumber;
  }

  Widget _buildCallHistoryItem(Map<String, dynamic> call) {
    return FutureBuilder<String>(
      future: _getContactName(call['phoneNumber']),
      builder: (context, snapshot) {
        String displayName = snapshot.data ?? call['phoneNumber'];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                call['type'] == 'missed'
                    ? Icons.call_missed
                    : call['type'] == 'outgoing'
                    ? Icons.call_made
                    : Icons.call_received,
                color: Colors.white,
              ),
            ),
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              formatTimeAgo(call['time']),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: Icon(
                call['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                color: call['isFavorite'] ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  call['isFavorite'] = !call['isFavorite'];
                });
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallDetailPage(callDetails: call),
                ),
              );
            },
          ),
        );
      },
    );
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

    return Container(
      padding: const EdgeInsets.all(16.0),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatisticTile('Total', totalCalls, Icons.call),
          _buildStatisticTile(
            'Missed',
            missedCalls,
            Icons.call_missed,
            color: Colors.red,
          ),
          _buildStatisticTile(
            'Outgoing',
            outgoingCalls,
            Icons.call_made,
            color: Colors.green,
          ),
          _buildStatisticTile(
            'Incoming',
            incomingCalls,
            Icons.call_received,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticTile(
    String label,
    int count,
    IconData icon, {
    Color color = Colors.black,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
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
          return (b['time'] ?? '').compareTo(a['time'] ?? '');
        case 'type':
          return (a['type'] ?? '').compareTo(b['type'] ?? '');
        case 'duration':
          return (b['duration'] ?? 0).compareTo(a['duration'] ?? 0);
        default:
          return 0;
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Call History',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Call History',
            onPressed: _exportCallHistory,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Call History',
            onPressed: _clearCallHistory,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          children: [
            _buildCallStatistics(),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _sortCriteria,
              items: const [
                DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                DropdownMenuItem(value: 'type', child: Text('Sort by Type')),
                DropdownMenuItem(
                  value: 'duration',
                  child: Text('Sort by Duration'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _sortCriteria = value ?? 'date';
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: filteredHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No call history found.',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredHistory.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final call = filteredHistory[i];
                          final timeAgo = formatTimeAgo(
                            DateTime.parse(call['time']),
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              child: Icon(
                                call['type'] == 'outgoing'
                                    ? Icons.call_made
                                    : call['type'] == 'incoming'
                                    ? Icons.call_received
                                    : Icons.call_missed,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              call['number'] ?? '',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              '${call['status'] ?? 'Unknown Status'}\n$timeAgo',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    call['isFavorite'] ?? false
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () => _toggleFavorite(i),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteCall(i),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CallDetailPage(callDetails: call),
                                ),
                              );
                            },
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
