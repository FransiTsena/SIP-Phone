import 'package:fe/api/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_page.dart';
import 'settings_page.dart';
import 'contacts_page.dart';
import 'login.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import '../utils/ringtone_helper.dart';
import '../utils/call_history_helper.dart';
import '../utils/sip_permissions_helper.dart';
import '../utils/sip_registration_helper.dart';
import '../widgets/phone_keypad/phone_keypad.dart';
import '../services/call_overlay_service.dart';
import '../utils/call_ui_prefs.dart';
// import '../utils/call_helpers.dart';

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
    with WidgetsBindingObserver
    implements SipUaHelperListener {
  // Bottom navigation index: 0 Dialer, 1 Contacts, 2 History, 3 Settings
  int _currentTabIndex = 0;
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  String _remoteNumber = '';
  DateTime?
  _callStartTime; // Timestamp when call actually started (CONFIRMED / accepted)
  bool _callPopupShown = false; // Prevent multiple dialogs
  // Helper to re-register with new credentials after profile/settings update

  void _makeCall() async {
    try {
      if (!await _requestPermissions()) {
        setState(() {
          _status = 'Microphone or camera permission denied';
        });
        return;
      }
      final number = _numberController.text.trim();
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
      final sipUri = 'sip:$number@${AppConfig.ip}';
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

  void _onNavTap(int index) {
    setState(() => _currentTabIndex = index);
  }

  void _startRingtone() => _ringtoneHelper.start();
  void _stopRingtone() => _ringtoneHelper.stop();

  void _startCallTimer() {
    _callTimer?.cancel();
    _callDurationSeconds = 0;
    _callStartTime = DateTime.now();
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

  Future<void> _logout() async {
    try {
      // End any active call
      _currentCall?.hangup();
      _stopRingtone();
      _stopCallTimer();
      // Stop SIP helper/registration
      _helper.stop();
      // Clear stored credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('username');
      await prefs.remove('access_token');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      // Even if something fails, try to navigate to login
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _status = state.state.toString();
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
        final number = _remoteNumber.isNotEmpty
            ? _remoteNumber
            : call.id?.toString() ?? call.toString();
        CallOverlayService.instance.showIncomingCall(
          number: number,
          onAccept: () {
            _stopRingtone();
            call.answer({
              'mediaConstraints': {'audio': true, 'video': false},
            });
            setState(() {
              _currentCall = call;
              _callDurationSeconds = 0;
              _callStartTime = null; // Will set when CONFIRMED
            });
            _startCallTimer();
          },
          onReject: () {
            _stopRingtone();
            call.hangup();
          },
          onSilence: _stopRingtone,
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
        _callStartTime = null; // Not started yet until CONFIRMED
      });
      _stopCallTimer();
      // Show popup early for outgoing call (ringing) globally
      _ensureCallPopupShown();
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
        _callStartTime ??= DateTime.now();
      });
      if (_callTimer == null) {
        _startCallTimer();
      }
      _ensureCallPopupShown();
      // Optionally auto-minimize on connect
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final autoMin = await CallUiPrefs.getAutoMinimizeOnConnect();
        if (autoMin && mounted && _currentCall != null) {
          // trigger minimize as if swiped down
          CallOverlayService.instance.hide();
          CallOverlayService.instance.showMiniCall(
            number: _remoteNumber.isNotEmpty
                ? _remoteNumber
                : _numberController.text,
            callStartTimeProvider: () => _callStartTime,
            onExpand: () {
              CallOverlayService.instance.hideMini();
              _ensureCallPopupShown();
            },
            onHangUp: () {
              _currentCall?.hangup();
            },
          );
        }
      });
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
      // Ensure any global overlay is closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CallOverlayService.instance.hide();
        CallOverlayService.instance.hideMini();
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
      // Recompute duration using start time for accuracy if available
      if (_callStartTime != null) {
        _callDurationSeconds = DateTime.now()
            .difference(_callStartTime!)
            .inSeconds;
      }
      _addCallHistory(number, type, status);
      setState(() {
        _currentCall = null;
        // _isMuted and _isSpeakerOn removed: now managed in CallPopup
        _callDurationSeconds = 0;
        _callStartTime = null;
        _callPopupShown = false;
      });
      return true;
    }
    return false;
  }

  final TextEditingController _numberController = TextEditingController();
  final SIPUAHelper _helper = SIPUAHelper();
  String _status = 'Not Registered';
  Call? _currentCall;
  // Mute and speaker state are now managed in CallPopup
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _helper.addSipUaHelperListener(this);
    _register();
    _loadCallHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Listen to lifecycle to adjust timers / UI when coming back from system phone interruptions
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_currentCall != null && _callStartTime != null) {
        // Force recompute of duration on resume
        setState(() {
          _callDurationSeconds = DateTime.now()
              .difference(_callStartTime!)
              .inSeconds;
        });
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  void _ensureCallPopupShown() {
    if (_currentCall == null) return;
    if (_callPopupShown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _callPopupShown = true;
      // Use global overlay to show active call UI
      CallOverlayService.instance.showActiveCall(
        number: _remoteNumber.isNotEmpty
            ? _remoteNumber
            : _numberController.text,
        status: _status,
        isIncoming: _currentCall?.direction == "INCOMING",
        onHangUp: () {
          _currentCall?.hangup();
          setState(() {
            _currentCall = null;
            _callDurationSeconds = 0;
            _callStartTime = null;
            _callPopupShown = false;
          });
        },
        onToggleMute: () {
          // TODO: Implement actual mute logic using SIP UA API if available
        },
        onToggleSpeaker: () {
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
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: Colors.blueGrey[900],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.teal[400],
                        child: const Icon(
                          Icons.swap_calls,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Transfer Call',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Target Number or SIP URI',
                          labelStyle: const TextStyle(color: Colors.tealAccent),
                          filled: true,
                          fillColor: Colors.blueGrey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_forwarded,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[400],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(controller.text.trim()),
                            icon: const Icon(Icons.send),
                            label: const Text('Transfer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          if (target != null && target.isNotEmpty) {
            String uri = target.startsWith('sip:')
                ? target
                : 'sip:$target@${AppConfig.ip}';
            try {
              if (kDebugMode) {
                print('[TRANSFER] Attempting transfer to: $uri');
                print('[TRANSFER] Current call state: \${_currentCall?.state}');
              }
              if (_currentCall != null &&
                  _currentCall!.state != CallStateEnum.HOLD) {
                print('[TRANSFER] Putting call on hold before transfer...');
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Transfer failed: $e')));
            }
          }
        },
        callStartTimeProvider: () => _callStartTime,
      );
    });
  }

  void _register() {
    final settings = SipRegistrationHelper.buildSettings(
      username: widget.username,
      password: widget.password,
      ip: AppConfig.ip,
    );
    _helper.start(settings);
  }

  Future<bool> _requestPermissions() async {
    return await SipPermissionsHelper.requestPermissions(context);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure popup shown for active call states
    if (_currentCall != null &&
        (_currentCall!.state == CallStateEnum.CONFIRMED ||
            _currentCall!.state == CallStateEnum.HOLD ||
            _currentCall!.state == CallStateEnum.PROGRESS)) {
      _ensureCallPopupShown();
    }
    Widget dialerBody = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final horizontalPadding = isWide ? constraints.maxWidth * 0.2 : 16.0;
        final fontSize = isWide ? 40.0 : 30.0;
        final keypadSpacing = isWide ? 32.0 : 18.0;
        final buttonFontSize = isWide ? 26.0 : 20.0;
        final buttonPadding = isWide
            ? const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: 32,
              left: horizontalPadding,
              right: horizontalPadding,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    _numberController.text.isEmpty
                        ? 'Enter number'
                        : _numberController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Theme.of(context).colorScheme.primary,
                      shadows: [
                        Shadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: keypadSpacing),
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
                SizedBox(height: keypadSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: buttonPadding,
                        textStyle: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 6,
                        shadowColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.4),
                      ),
                      onPressed: _numberController.text.isNotEmpty
                          ? _makeCall
                          : null,
                      icon: const Icon(Icons.call, size: 30),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('Call'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 24 : 12),
              ],
            ),
          ),
        );
      },
    );

    Widget contactsBody = const ContactsPage();
    Widget historyBody = CallHistoryPage(callHistory: _callHistory);
    Widget settingsBody = ProfileSettingsPage(
      initialUsername: widget.username,
      initialAccessToken: '',
      autoPopOnSave: false,
      onSaved: () {
        // Re-register with potential updated credentials/IP
        _helper.stop();
        _register();
      },
      onLogout: _logout,
    );

    final bodies = [dialerBody, contactsBody, historyBody, settingsBody];

    // Responsive shell: NavigationRail on wide screens, bottom bar on narrow
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUltraWide =
            constraints.maxWidth > 1180; // show side recent calls
        final useRail = constraints.maxWidth > 900;

        Widget content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: bodies[_currentTabIndex],
        );

        // Recent calls side panel when on dialer & ultra wide
        Widget? recentCallsPanel;
        if (_currentTabIndex == 0 && isUltraWide) {
          recentCallsPanel = _RecentCallsPanel(
            calls: _callHistory.take(12).toList(),
            onTap: (number) {
              setState(() => _numberController.text = number);
            },
          );
        }

        return SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Row(
              children: [
                if (useRail)
                  NavigationRail(
                    selectedIndex: _currentTabIndex,
                    onDestinationSelected: _onNavTap,
                    extended: constraints.maxWidth > 1250,
                    labelType: constraints.maxWidth > 1100
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.15),
                        child: Icon(
                          Icons.phone_in_talk,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dialpad_outlined),
                        selectedIcon: Icon(Icons.dialpad),
                        label: Text('Dialer'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.contacts_outlined),
                        selectedIcon: Icon(Icons.contacts),
                        label: Text('Contacts'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: Text('History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                if (useRail) const VerticalDivider(width: 1),
                Expanded(child: content),
                if (recentCallsPanel != null) recentCallsPanel,
              ],
            ),
            bottomNavigationBar: useRail
                ? null
                : NavigationBar(
                    selectedIndex: _currentTabIndex,
                    onDestinationSelected: _onNavTap,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dialpad_outlined),
                        selectedIcon: Icon(Icons.dialpad),
                        label: 'Dialer',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.contacts_outlined),
                        selectedIcon: Icon(Icons.contacts),
                        label: 'Contacts',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: 'History',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _RecentCallsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> calls;
  final ValueChanged<String> onTap;
  const _RecentCallsPanel({required this.calls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(.06)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Calls',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: calls.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final call = calls[i];
                final number = call['number']?.toString() ?? '';
                final status = call['status']?.toString() ?? '';
                final type = call['type']?.toString() ?? '';
                IconData icon;
                Color color;
                switch (type) {
                  case 'outgoing':
                    icon = Icons.call_made;
                    color = Colors.green;
                    break;
                  case 'incoming':
                    icon = Icons.call_received;
                    color = Colors.blue;
                    break;
                  case 'missed':
                    icon = Icons.call_missed;
                    color = Colors.redAccent;
                    break;
                  default:
                    icon = Icons.call;
                    color = Colors.grey;
                }
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withOpacity(.12),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  title: Text(
                    number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(.55),
                    ),
                  ),
                  onTap: () => onTap(number),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
