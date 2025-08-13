import 'package:flutter/material.dart';

class IncomingCallPopup extends StatelessWidget {
  final String number;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallPopup({
    super.key,
    required this.number,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Incoming Call from $number'),
      actions: [
        TextButton(onPressed: onReject, child: const Text('Reject')),
        TextButton(onPressed: onAccept, child: const Text('Accept')),
      ],
    );
  }
}
