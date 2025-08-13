import 'package:fe/screens/ticker.dart';
import 'package:flutter/material.dart';

String formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}

class CallPopup extends StatefulWidget {
  final String number;
  final String status;
  final VoidCallback onHangUp;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleHold;
  final VoidCallback onTransferCall;
  final bool isIncoming;
  final DateTime? Function()?
  callStartTimeProvider; // Provides dynamic start time
  // When true, this widget will call Navigator.pop on hang up; set to false when used in overlay.
  final bool closeSelfOnHangUp;
  // Optional: minimize handler to collapse into mini chip
  final VoidCallback? onMinimize;

  const CallPopup({
    super.key,
    required this.number,
    required this.status,
    required this.onHangUp,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleHold,
    required this.onTransferCall,
    this.isIncoming = false,
    this.callStartTimeProvider,
    this.closeSelfOnHangUp = true,
    this.onMinimize,
  });

  @override
  State<CallPopup> createState() => _CallPopupState();
}

class _CallPopupState extends State<CallPopup> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isOnHold = false;
  int _callDurationSeconds = 0; // Computed from provided start time each tick
  late final Ticker _ticker;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final start = widget.callStartTimeProvider?.call();
    if (start != null) {
      final now = DateTime.now();
      final secs = now.difference(start).inSeconds;
      if (secs != _callDurationSeconds) {
        setState(() {
          _callDurationSeconds = secs;
        });
      }
    } else if (_callDurationSeconds != 0) {
      setState(() {
        _callDurationSeconds = 0;
      });
    }
  }

  @override
  void dispose() {
    _running = false;
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: Colors.brown,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final shortest = width < height ? width : height;
            // Scale UI against a ~400px reference, clamped to reasonable bounds
            final scaleRaw = shortest / 400.0;
            final scale = scaleRaw.clamp(0.7, 1.6);

            // Sizes derived from scale
            final avatarRadius = (54.0 * scale).clamp(36.0, 90.0);
            final avatarIcon = (54.0 * scale).clamp(28.0, 80.0);
            final controlSize = (64.0 * scale).clamp(48.0, 84.0);
            final controlIcon = (32.0 * scale).clamp(20.0, 44.0);
            final hangupSize = (80.0 * scale).clamp(64.0, 110.0);
            final hangupIcon = (40.0 * scale).clamp(28.0, 64.0);

            final spacingLg = (24.0 * scale).clamp(12.0, 32.0);
            final spacingMd = (18.0 * scale).clamp(10.0, 24.0);
            final spacingSm = (8.0 * scale).clamp(6.0, 16.0);

            final numberFs = (28.0 * scale).clamp(18.0, 36.0);
            final statusFs = (18.0 * scale).clamp(12.0, 22.0);
            final durationFs = (22.0 * scale).clamp(14.0, 26.0);
            final labelFs = (14.0 * scale).clamp(11.0, 16.0);

            return SizedBox(
              height: height,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (width * 0.06).clamp(12.0, 32.0),
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    // Avatar and info
                    Column(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.blue[700],
                          child: Icon(
                            Icons.phone_in_talk,
                            color: Colors.white,
                            size: avatarIcon,
                          ),
                        ),
                        SizedBox(height: spacingMd),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.number.isNotEmpty
                                ? widget.number
                                : 'In Call',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: numberFs,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: spacingSm + 2),
                        Text(
                          widget.isIncoming ? 'Incoming Call' : 'In Call',
                          style: TextStyle(
                            fontSize: statusFs,
                            color: widget.isIncoming
                                ? Colors.greenAccent[400]
                                : Colors.blue[200],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: spacingSm),
                        if (_callDurationSeconds > 0)
                          Text(
                            formatDuration(_callDurationSeconds),
                            style: TextStyle(
                              fontSize: durationFs,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (_callDurationSeconds == 0)
                          Text(
                            widget.status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: statusFs,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Controls at the bottom - Wrap so it adapts to width
                    Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: spacingLg,
                      runSpacing: spacingLg * 0.6,
                      children: [
                        _ActionButton(
                          size: controlSize,
                          iconSize: controlIcon,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          labelFontSize: labelFs,
                          backgroundColor: _isMuted
                              ? Colors.grey
                              : Colors.blue[800]!,
                          shadowColor: Colors.blue.withOpacity(0.18),
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          onTap: () {
                            setState(() => _isMuted = !_isMuted);
                            widget.onToggleMute();
                          },
                        ),
                        _ActionButton(
                          size: controlSize,
                          iconSize: controlIcon,
                          label: _isOnHold ? 'Resume' : 'Hold',
                          labelFontSize: labelFs,
                          backgroundColor: (_isOnHold
                              ? Colors.green[200]
                              : Colors.green[700])!,
                          shadowColor: Colors.purple.withOpacity(0.18),
                          icon: _isOnHold ? Icons.play_arrow : Icons.pause,
                          onTap: () {
                            setState(() => _isOnHold = !_isOnHold);
                            widget.onToggleHold();
                          },
                        ),
                        _ActionButton(
                          size: controlSize,
                          iconSize: controlIcon,
                          label: _isSpeakerOn ? 'Speaker Off' : 'Speaker',
                          labelFontSize: labelFs,
                          backgroundColor: _isSpeakerOn
                              ? Colors.orange
                              : Colors.blue[800]!,
                          shadowColor: Colors.orange.withOpacity(0.18),
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                          onTap: () {
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
                            widget.onToggleSpeaker();
                          },
                        ),
                        _ActionButton(
                          size: controlSize,
                          iconSize: controlIcon,
                          label: 'Transfer',
                          labelFontSize: labelFs,
                          backgroundColor: Colors.teal[700]!,
                          shadowColor: Colors.teal.withOpacity(0.18),
                          icon: Icons.swap_calls,
                          onTap: widget.onTransferCall,
                        ),
                      ],
                    ),
                    SizedBox(height: spacingLg),
                    // Hang up button centered
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (widget.closeSelfOnHangUp) {
                            Navigator.of(context).pop();
                          }
                          widget.onHangUp();
                        },
                        child: Column(
                          children: [
                            Container(
                              width: hangupSize,
                              height: hangupSize,
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
                              child: Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: hangupIcon,
                              ),
                            ),
                            SizedBox(height: spacingSm),
                            Text(
                              'Hang Up',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: labelFs,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 800) {
          // fast swipe down to minimize
          widget.onMinimize?.call();
        }
      },
      child: content,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final String label;
  final double labelFontSize;
  final Color backgroundColor;
  final Color shadowColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.size,
    required this.iconSize,
    required this.label,
    required this.labelFontSize,
    required this.backgroundColor,
    required this.shadowColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size * 1.6,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: labelFontSize),
            ),
          ),
        ],
      ),
    );
  }
}
