import 'package:flutter/material.dart';

String formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}

class CallPopup extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Container(
        width: 340,
        height: 520,
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
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
        ),
        child: Stack(
          children: [
            // Top bar (signal, wifi, battery)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
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
            ),
            // Avatar and info
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.blue[700],
                    child: Icon(
                      Icons.phone_in_talk,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    number.isNotEmpty ? number : 'In Call',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isIncoming ? 'Incoming Call' : 'In Call',
                    style: TextStyle(
                      fontSize: 18,
                      color: isIncoming
                          ? Colors.greenAccent[400]
                          : Colors.blue[200],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (callDurationSeconds > 0)
                    Text(
                      formatDuration(callDurationSeconds),
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (callDurationSeconds == 0)
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Controls at the bottom
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  GestureDetector(
                    onTap: onToggleMute,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isMuted ? Colors.grey : Colors.blue[800],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isMuted ? 'Unmute' : 'Mute',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hold button
                  GestureDetector(
                    onTap: onToggleHold,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.purple[700],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hold',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Hang up button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onHangUp();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent,
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hang Up',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Speaker button
                  GestureDetector(
                    onTap: onToggleSpeaker,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isSpeakerOn
                                ? Colors.orange
                                : Colors.blue[800],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSpeakerOn ? Icons.volume_up : Icons.hearing,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSpeakerOn ? 'Speaker Off' : 'Speaker',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Transfer button
                  GestureDetector(
                    onTap: onTransferCall,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.teal[700],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.swap_calls,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Transfer',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
