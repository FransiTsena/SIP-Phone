import 'package:flutter/material.dart';
import 'package:fe/screens/ticker.dart';

class MiniCallChip extends StatefulWidget {
  final String number;
  final DateTime? Function()? callStartTimeProvider;
  final VoidCallback onExpand;
  final VoidCallback onHangUp;

  const MiniCallChip({
    super.key,
    required this.number,
    required this.callStartTimeProvider,
    required this.onExpand,
    required this.onHangUp,
  });

  @override
  State<MiniCallChip> createState() => _MiniCallChipState();
}

class _MiniCallChipState extends State<MiniCallChip> {
  late Ticker _ticker;
  bool _running = true;
  int _secs = 0;
  Offset _offset = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration d) {
    if (!_running) return;
    final start = widget.callStartTimeProvider?.call();
    final secs = start != null ? DateTime.now().difference(start).inSeconds : 0;
    if (secs != _secs) {
      setState(() => _secs = secs);
    }
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
    final chip = Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
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
            Text(_fmt(_secs), style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onExpand,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.open_in_full,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onHangUp,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.call_end, color: Colors.redAccent, size: 18),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: GestureDetector(
              onPanUpdate: (d) {
                setState(() {
                  _offset = Offset(
                    (_offset.dx + d.delta.dx).clamp(
                      8,
                      MediaQuery.of(context).size.width - 8 - 220,
                    ),
                    (_offset.dy + d.delta.dy).clamp(
                      8,
                      MediaQuery.of(context).size.height - 8 - 48,
                    ),
                  );
                });
              },
              onTap: widget.onExpand,
              child: chip,
            ),
          ),
        ],
      ),
    );
  }
}
