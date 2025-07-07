import 'package:sip_ua/sip_ua.dart';
import 'package:flutter/material.dart';

class SipRegistrationHelper {
  static UaSettings buildSettings({
    required String username,
    required String password,
    String ip = '10.42.0.17',
  }) {
    final settings = UaSettings();
    settings.webSocketUrl = 'ws://$ip:8088/ws';
    settings.webSocketSettings = WebSocketSettings();
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = 'sip:$username@$ip';
    settings.authorizationUser = username;
    settings.password = password;
    settings.displayName = 'FE SIP';
    settings.userAgent = 'SIP FE';
    settings.transportType = TransportType.WS;
    return settings;
  }

  static void showRegistrationErrorDialog(
    BuildContext context,
    RegistrationState state,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(
          'Could not register to SIP server. State: ${state.state}\nPlease check your credentials and network.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
