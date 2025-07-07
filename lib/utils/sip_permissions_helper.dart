import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class SipPermissionsHelper {
  static Future<bool> requestPermissions(BuildContext context) async {
    final mic = await Permission.microphone.request();
    final cam = await Permission.camera.request();
    if (!mic.isGranted || !cam.isGranted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Microphone and camera permissions are required to make calls.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}
