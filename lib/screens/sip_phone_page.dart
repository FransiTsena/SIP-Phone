import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sip_ua/sip_ua.dart';
import 'call_popup.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_page.dart';
import 'incoming_call_popup.dart';
import 'profile_settings_page.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import '../utils/ringtone_helper.dart';
import '../utils/call_history_helper.dart';
import '../utils/sip_permissions_helper.dart';
import '../utils/sip_registration_helper.dart';
import '../widgets/phone_keypad/phone_keypad.dart';
// import '../utils/call_helpers.dart';
import '../widgets/custom_app_bar.dart';

class SipPhonePage extends StatefulWidget {
  final String username;
  final String password;
  const SipPhonePage({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<SipPhonePage> createState() => _SipPhonePageState();
}

class _SipPhonePageState extends State<SipPhonePage>
    implements SipUaHelperListener {
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String _remoteNumber = '';
  // Helper to re-register with new credentials after profile/settings update
  void _registerWithCredentials(String username, String password) {
    final settings = SipRegistrationHelper.buildSettings(
      username: username,
      password: password,
    );
    _helper.start(settings);
  }

  void _makeCall() async {
    try {
      if (!await _requestPermissions()) {
        setState(() {
          _status = 'Microphone or camera permission denied';
        });
        return;
      }
      final number = _numberController.text.trim();
      final ip = '10.42.0.17';
      final validNumber = RegExp(r'^\d{2,}');
      if (number.isEmpty) {
        setState(() {
          _status = 'Please enter a phone number.';
        });
        return;
      }
      if (!validNumber.hasMatch(number)) {
        setState(() {
          _status = 'Invalid number format. Use only digits.';
        });
        return;
      }
      final sipUri = 'sip:$number@$ip';
      if (kDebugMode) {
        print('Dialing: $sipUri');
      }
      await _addCallHistory(number, 'outgoing', 'Dialing');
      try {
        _helper.call(sipUri, voiceOnly: true);
      } catch (e, st) {
        if (kDebugMode) {
          print('Error in SIP call: $e\n$st');
        }
        setState(() {
          _status = 'Call failed: $e';
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Call failed: $e')));
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('Error making call: $e\n$st');
      }
      setState(() {
        _status = 'Call failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Call failed: $e')));
      }
    }
  }

  Future<void> _addCallHistory(
    String number,
    String type,
    String status,
  ) async {
    await CallHistoryHelper.addCallHistory(number, type, status);
    final history = await CallHistoryHelper.loadCallHistory();
    setState(() {
      _callHistory = history;
    });
  }

  Future<void> _loadCallHistory() async {
    final history = await CallHistoryHelper.loadCallHistory();
    setState(() {
      _callHistory = history;
    });
  }

  void _startRingtone() => _ringtoneHelper.start();
  void _stopRingtone() => _ringtoneHelper.stop();

  void _startCallTimer() {
    _callTimer?.cancel();
    _callDurationSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _status = state.state.toString();
      _isRegistered = state.state == RegistrationStateEnum.REGISTERED;
    });
    if (state.state != RegistrationStateEnum.REGISTERED) {
      if (kDebugMode) {
        print('Registration state: ${state.state}');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SipRegistrationHelper.showRegistrationErrorDialog(context, state);
      });
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {
    setState(() {
      _status = 'Call: ${state.state}';
      _remoteNumber = _extractRemoteNumber(call);
    });

    if (kDebugMode) {
      print(
        "[DEBUG] callStateChanged: state.state = '${state.state}', call.direction = '${call.direction}'",
      );
    }

    if (_handleIncomingCall(call, state)) return;
    if (_handleOutgoingCall(call, state)) return;
    if (_handleCallConfirmedOrHold(call, state)) return;
    if (_handleCallEndedOrFailed(call, state)) return;
    if (state.state == CallStateEnum.FAILED) {
      if (kDebugMode) {
        print('Call failed: ${state.cause}');
      }
      setState(() {
        _status += ' (${state.cause})';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    }
    if (kDebugMode) {
      print('CallStateEnum value: ${state.state}');
      print('Call object: $call');
    }
  }

  String _extractRemoteNumber(Call call) {
    if (call.remote_identity != null) {
      final match = RegExp(
        r'sip:([^@]+)@',
      ).firstMatch(call.remote_identity.toString());
      return match != null
          ? match.group(1) ?? ''
          : call.remote_identity.toString();
    }
    return call.id?.toString() ?? '';
  }

  bool _handleIncomingCall(Call call, CallState state) {
    if (call.direction == "INCOMING" && state.state == CallStateEnum.PROGRESS) {
      if (kDebugMode) {
        print('[DEBUG] Showing IncomingCallPopup dialog');
      }
      _startRingtone();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => IncomingCallPopup(
            number: _remoteNumber.isNotEmpty
                ? _remoteNumber
                : call.id?.toString() ?? call.toString(),
            onAccept: () {
              _stopRingtone();
              Navigator.of(context).pop();
              call.answer({
                'mediaConstraints': {'audio': true, 'video': false},
              });
              setState(() {
                _currentCall = call;
                _callDurationSeconds = 0;
              });
              _startCallTimer();
            },
            onReject: () {
              _stopRingtone();
              Navigator.of(context).pop();
              call.hangup();
            },
          ),
        );
      });
      return true;
    }
    return false;
  }

  bool _handleOutgoingCall(Call call, CallState state) {
    if (call.direction != "INCOMING" && state.state == CallStateEnum.PROGRESS) {
      _stopRingtone();
      setState(() {
        _currentCall = call;
        _callDurationSeconds = 0;
      });
      _stopCallTimer();
      return true;
    }
    return false;
  }

  bool _handleCallConfirmedOrHold(Call call, CallState state) {
    if (state.state == CallStateEnum.CONFIRMED ||
        state.state == CallStateEnum.HOLD) {
      _stopRingtone();
      setState(() {
        _currentCall = call;
      });
      if (_callTimer == null) {
        _startCallTimer();
      }
      return true;
    }
    return false;
  }

  bool _handleCallEndedOrFailed(Call call, CallState state) {
    if (state.state == CallStateEnum.FAILED ||
        state.state == CallStateEnum.ENDED ||
        state.state == CallStateEnum.NONE) {
      _stopRingtone();
      _stopCallTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
      final number = _remoteNumber.isNotEmpty
          ? _remoteNumber
          : _numberController.text.trim();
      String type = call.direction == "INCOMING" ? 'incoming' : 'outgoing';
      String status = state.state == CallStateEnum.FAILED
          ? 'Failed'
          : (state.state == CallStateEnum.ENDED && _callDurationSeconds == 0
                ? 'Missed'
                : 'Ended');
      _addCallHistory(number, type, status);
      setState(() {
        _currentCall = null;
        _isMuted = false;
        _isSpeakerOn = false;
        _callDurationSeconds = 0;
      });
      return true;
    }
    return false;
  }

  final TextEditingController _numberController = TextEditingController();
  final SIPUAHelper _helper = SIPUAHelper();
  String _status = 'Not Registered';
  bool _isRegistered = false;
  Call? _currentCall;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  List<Map<String, dynamic>> _callHistory = [];
  final RingtoneHelper _ringtoneHelper = RingtoneHelper();

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify notify) {}

  @override
  void onNewReinvite(ReInvite invite) {}

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    await prefs.remove('password');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _helper.addSipUaHelperListener(this);
    _register();
    _loadCallHistory();
  }

  void _register() {
    final settings = SipRegistrationHelper.buildSettings(
      username: widget.username,
      password: widget.password,
    );
    _helper.start(settings);
  }

  Future<bool> _requestPermissions() async {
    return await SipPermissionsHelper.requestPermissions(context);
  }

  @override
  Widget build(BuildContext context) {
    // Show CallPopup for ongoing calls
    if (_currentCall != null &&
        (_currentCall!.state == CallStateEnum.CONFIRMED ||
            _currentCall!.state == CallStateEnum.HOLD ||
            _currentCall!.state == CallStateEnum.PROGRESS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => CallPopup(
              number: _remoteNumber.isNotEmpty
                  ? _remoteNumber
                  : _numberController.text,
              status: _status,
              isMuted: _isMuted,
              isSpeakerOn: _isSpeakerOn,
              onHangUp: () {
                _currentCall?.hangup();
                setState(() {
                  _currentCall = null;
                  _isMuted = false;
                  _isSpeakerOn = false;
                  _callDurationSeconds = 0;
                });
              },
              onToggleMute: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
                // TODO: Implement actual mute logic using SIP UA API if available
              },
              onToggleSpeaker: () {
                setState(() {
                  _isSpeakerOn = !_isSpeakerOn;
                });
                // TODO: Implement actual speakerphone logic if needed
              },
              onToggleHold: () {
                if (_currentCall != null) {
                  if (_currentCall!.state == CallStateEnum.HOLD) {
                    _currentCall!.unhold();
                  } else {
                    _currentCall!.hold();
                  }
                  setState(() {});
                }
              },
              onTransferCall: () async {
                String? target = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Transfer Call'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Target Number or SIP URI',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(controller.text.trim()),
                          child: const Text('Transfer'),
                        ),
                      ],
                    );
                  },
                );
                if (target != null && target.isNotEmpty) {
                  String uri = target.startsWith('sip:')
                      ? target
                      : 'sip:$target@10.42.0.17';
                  try {
                    if (kDebugMode) {
                      print('[TRANSFER] Attempting transfer to: $uri');
                      print(
                        '[TRANSFER] Current call state: \\${_currentCall?.state}',
                      );
                    }
                    // Put call on hold before transfer (some servers require this)
                    if (_currentCall != null &&
                        _currentCall!.state != CallStateEnum.HOLD) {
                      print(
                        '[TRANSFER] Putting call on hold before transfer...',
                      );
                      _currentCall!.hold();
                    }
                    print('[TRANSFER] Calling refer(uri)');
                    _currentCall?.refer(uri);
                    print('[TRANSFER] refer(uri) called');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Transfer initiated to $uri')),
                    );
                  } catch (e, st) {
                    print('[TRANSFER] Transfer failed: $e\n$st');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Transfer failed: $e')),
                    );
                  }
                }
              },
              callDurationSeconds: _callDurationSeconds,
              isIncoming: _currentCall?.direction == "INCOMING",
            ),
          );
        }
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'SIP Phone FE',
        onHistory: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CallHistoryPage(callHistory: _callHistory),
            ),
          );
        },
        onSettings: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileSettingsPage(
                initialUsername: widget.username,
                initialPassword: widget.password,
              ),
            ),
          );
          if (result == true) {
            setState(() {
              // Updated status
            });
          }
        },
        onLogout: () async {
          await _logout();
        },
      ),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  _numberController.text.isEmpty
                      ? 'Enter number'
                      : _numberController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 18),
              PhoneKeypad(
                controller: _numberController,
                onKeyAdd: (String val) {
                  setState(() {
                    _numberController.text += val;
                  });
                },
                onKeyDelete: (String text) {
                  setState(() {
                    if (text.isNotEmpty) {
                      _numberController.text = text.substring(
                        0,
                        text.length - 1,
                      );
                    }
                  });
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: _numberController.text.isNotEmpty
                        ? _makeCall
                        : null,
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
