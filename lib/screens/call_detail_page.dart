import 'package:flutter/material.dart';

class CallDetailPage extends StatelessWidget {
  final Map<String, dynamic> callDetails;

  const CallDetailPage({super.key, required this.callDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number: ${callDetails['number']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${callDetails['type']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${callDetails['status']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${callDetails['time']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (callDetails['duration'] != null)
              Text(
                'Duration: ${callDetails['duration']} seconds',
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
