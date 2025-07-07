import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import 'package:sip_ua/sip_ua.dart';

String formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}

class CallPopupHandlers {
  static void hangUp(Call? currentCall, Function updateState) {
    if (currentCall != null) {
      currentCall.hangup();
      updateState(() {
        currentCall = null;
      });
    }
  }

  static void toggleMute(Call? currentCall, bool isMuted, Function updateState) {
    if (currentCall != null) {
      if (isMuted) {
        currentCall.unmute();
      } else {
        currentCall.mute();
      }
      updateState(() {
        isMuted = !isMuted;
      });
    }
  }

  static void toggleSpeaker(bool isSpeakerOn, Function updateState) {
    Helper.setSpeakerphoneOn(!isSpeakerOn);
    updateState(() {
      isSpeakerOn = !isSpeakerOn;
    });
  }

  static void toggleHold(Call? currentCall, Function updateState) {
    if (currentCall != null) {
      if (currentCall.state == CallStateEnum.HOLD) {
        currentCall.unhold();
      } else {
        currentCall.hold();
      }
      updateState(() {
        // Update status or other state variables
      });
    }
  }

  static Future<void> transferCall(
    BuildContext context,
    Call? currentCall,
    Function updateState,
  ) async {
    if (currentCall != null) {
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
          updateState(() {
            // Update status or other state variables
          });
          return;
        }

        final transferUri = 'sip:$transferNumber@10.42.0.17';
        currentCall.refer(transferUri);
        updateState(() {
          // Update status or other state variables
        });
      }
    }
  }
}


class CallPopup extends StatefulWidget {
  final String number;
  final String status;
  final bool isMuted;
  final bool isSpeakerOn;
  final VoidCallback onHangUp;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleHold;
  final VoidCallback onTransferCall;
  final int callDurationSeconds;
  final bool isIncoming;

  const CallPopup({
    super.key,
    required this.number,
    required this.status,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.onHangUp,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleHold,
    required this.onTransferCall,
    this.callDurationSeconds = 0,
    this.isIncoming = false,
  });

  @override
  State<CallPopup> createState() => _CallPopupState();
}

class _CallPopupState extends State<CallPopup> {
  late bool isMuted;
  late bool isSpeakerOn;
  bool isOnHold = false;

  @override
  void initState() {
    super.initState();
    isMuted = widget.isMuted;
    isSpeakerOn = widget.isSpeakerOn;
  }

  void toggleMute() {
    widget.onToggleMute();
    setState(() {
      isMuted = !isMuted;
    });
  }

  void toggleSpeaker() {
    widget.onToggleSpeaker();
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
  }

  void toggleHold() {
    widget.onToggleHold();
    setState(() {
      isOnHold = !isOnHold;
    });
  }

  void transferCall() {
    widget.onTransferCall();
    setState(() {
      // Optionally, you can add a local state for transfer if you want to reflect it visually
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth * 0.9,
            height: constraints.maxHeight * 0.8,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.wifi,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.battery_full,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                    ],
                  ),
                ),
                // Avatar and info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: constraints.maxWidth * 0.15,
                        backgroundColor: Colors.blue[700],
                        child: Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: constraints.maxWidth * 0.15,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.number.isNotEmpty ? widget.number : 'In Call',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isIncoming ? 'Incoming Call' : 'In Call',
                        style: TextStyle(
                          fontSize: 18,
                          color: widget.isIncoming
                              ? Colors.greenAccent[400]
                              : Colors.blue[200],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.callDurationSeconds > 0)
                        Text(
                          formatDuration(widget.callDurationSeconds),
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (widget.callDurationSeconds == 0)
                        Text(
                          widget.status,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Controls
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: isMuted ? Icons.mic_off : Icons.mic,
                        label: isMuted ? 'Unmute' : 'Mute',
                        color: isMuted ? Colors.grey : Colors.blue.shade800,
                        onTap: toggleMute,
                      ),
                      _buildControlButton(
                        icon: isOnHold ? Icons.play_arrow : Icons.pause,
                        label: isOnHold ? 'Resume' : 'Hold',
                        color: isOnHold ? Colors.green : Colors.orange,
                        onTap: toggleHold,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        label: 'Hang Up',
                        color: Colors.red,
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onHangUp();
                        },
                      ),
                      _buildControlButton(
                        icon: isSpeakerOn ? Icons.volume_up : Icons.hearing,
                        label: isSpeakerOn ? 'Speaker Off' : 'Speaker',
                        color: isSpeakerOn
                            ? Colors.orange
                            : Colors.blue.shade800,
                        onTap: toggleSpeaker,
                      ),
                      _buildControlButton(
                        icon: Icons.call_split,
                        label: 'Transfer',
                        color: Colors.blue.shade800,
                        onTap: transferCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
