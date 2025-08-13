import 'package:flutter/material.dart';
import 'package:fe/screens/ticker.dart';

class CallTopBar extends StatefulWidget {
  final String number;
  final DateTime? Function()? callStartTimeProvider;
  final VoidCallback onExpand;
  final VoidCallback onHangUp;

  const CallTopBar({
    super.key,
    required this.number,
    required this.callStartTimeProvider,
    required this.onExpand,
    required this.onHangUp,
  });

  @override
  State<CallTopBar> createState() => _CallTopBarState();
}

class _CallTopBarState extends State<CallTopBar> {
  late Ticker _ticker;
  bool _running = true;
  int _secs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration d) {
    if (!_running) return;
    final start = widget.callStartTimeProvider?.call();
    final secs = start != null ? DateTime.now().difference(start).inSeconds : 0;
    if (secs != _secs) setState(() => _secs = secs);
  }

  @override
  void dispose() {
    _running = false;
    _ticker.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmt(_secs),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onExpand,
                  icon: const Icon(
                    Icons.open_in_full,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                IconButton(
                  onPressed: widget.onHangUp,
                  icon: const Icon(
                    Icons.call_end,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
