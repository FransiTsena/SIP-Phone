import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sip_ua/sip_ua.dart';
import 'call_popup.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_page.dart';
import 'incoming_call_popup.dart';
import 'profile_settings_page.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import '../utils/ringtone_helper.dart';
import '../utils/call_history_helper.dart';
import '../utils/sip_permissions_helper.dart';
import '../utils/sip_registration_helper.dart';
import '../widgets/phone_keypad/phone_keypad.dart';

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

  void _hangUp() {
    if (_currentCall != null) {
      _currentCall!.hangup();
      _stopCallTimer();
      setState(() {
        _currentCall = null;
        _isMuted = false;
        _isSpeakerOn = false;
        _callDurationSeconds = 0;
      });
    }
  }

  void _toggleMute() {
    if (_currentCall != null) {
      setState(() {
        if (_isMuted) {
          _currentCall!.unmute();
        } else {
          _currentCall!.mute();
        }
        _isMuted = !_isMuted;
      });
    }
  }

  void _toggleSpeaker() {
    setState(() {
      Helper.setSpeakerphoneOn(!_isSpeakerOn);
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _toggleHold() {
    if (_currentCall != null) {
      if (_currentCall!.state == CallStateEnum.HOLD) {
        _currentCall!.unhold();
      } else {
        _currentCall!.hold();
      }
      setState(() {
        _status = _currentCall!.state == CallStateEnum.HOLD
            ? 'Call on Hold'
            : 'Call Resumed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show CallPopup for outgoing calls in PROGRESS, CONFIRMED, or HOLD states
    if (_currentCall != null &&
        ((_currentCall!.state == CallStateEnum.CONFIRMED ||
                _currentCall!.state == CallStateEnum.HOLD) ||
            (_currentCall!.state == CallStateEnum.PROGRESS &&
                _currentCall?.direction != "INCOMING"))) {
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
              onHangUp: _hangUp,
              onToggleMute: _toggleMute,
              onToggleSpeaker: _toggleSpeaker,
              onToggleHold: _toggleHold,
              onTransferCall: _transferCall,
              callDurationSeconds: _callDurationSeconds,
              isIncoming: _currentCall?.direction == "INCOMING",
            ),
          );
        }
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                Colors.blueAccent.withOpacity(0.8),
                Colors.purpleAccent.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text('SIP Phone FE'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Call History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CallHistoryPage(callHistory: _callHistory),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Profile/Settings',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsPage(
                    initialUsername: widget.username,
                    initialPassword: widget.password,
                  ),
                ),
              );
              if (result == true) {
                final prefs = await SharedPreferences.getInstance();
                final newUsername =
                    prefs.getString('username') ?? widget.username;
                final newPassword =
                    prefs.getString('password') ?? widget.password;
                setState(() {
                  _status = 'Re-registering...';
                });
                _helper.removeSipUaHelperListener(this);
                _helper.addSipUaHelperListener(this);
                _helper.stop();
                Future.delayed(const Duration(milliseconds: 500), () {
                  _registerWithCredentials(newUsername, newPassword);
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? null
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
      ),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(),

              // Status display
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.indigo,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              // Number display
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),

                child: Center(
                  child: Text(
                    _numberController.text.isEmpty
                        ? 'Enter number'
                        : _numberController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Phone keypad
              PhoneKeypad(
                onInput: (val) {
                  _numberController.text += val;
                  setState(() {});
                },
                onDelete: () {
                  if (_numberController.text.isNotEmpty) {
                    _numberController.text = _numberController.text.substring(
                      0,
                      _numberController.text.length - 1,
                    );
                    setState(() {});
                  }
                },
                onCall: _isRegistered ? _makeCall : () {},
                callEnabled: _isRegistered,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
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

  void _makeCall() async {
    if (!await _requestPermissions()) {
      setState(() {
        _status = 'Microphone or camera permission denied';
      });
      return;
    }
    final number = _numberController.text.trim();
    final ip = '10.42.0.17';
    final validNumber = RegExp(r'^\d{2,}$');
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
    _helper.call(sipUri, voiceOnly: true);
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

  void _transferCall() async {
    if (_currentCall != null) {
      final transferNumber = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final TextEditingController transferController =
              TextEditingController();
          return AlertDialog(
            title: const Text('Transfer Call'),
            content: TextField(
              controller: transferController,
              decoration: const InputDecoration(
                hintText: 'Enter target number',
              ),
              keyboardType: TextInputType.phone,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(transferController.text.trim()),
                child: const Text('Transfer'),
              ),
            ],
          );
        },
      );

      if (transferNumber != null && transferNumber.isNotEmpty) {
        final validNumber = RegExp(r'^\d{2,}$');
        if (!validNumber.hasMatch(transferNumber)) {
          setState(() {
            _status = 'Invalid transfer number format. Use only digits.';
          });
          return;
        }

        final transferUri = 'sip:$transferNumber@10.42.0.17';
        if (kDebugMode) {
          print('Transferring call to: $transferUri');
        }
        _currentCall!.refer(transferUri);
        setState(() {
          _status = 'Call transferred to $transferNumber';
        });
      }
    }
  }
}
