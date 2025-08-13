import 'dart:async';

/// A simple ticker class for periodic callbacks, similar to AnimationController's Ticker.
class Ticker {
  final void Function(Duration elapsed) onTick;
  Timer? _timer;
  DateTime? _start;
  bool _isActive = false;

  Ticker(this.onTick);

  void start() {
    _start = DateTime.now();
    _isActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive) return;
      final elapsed = DateTime.now().difference(_start!);
      onTick(elapsed);
    });
  }

  void dispose() {
    _isActive = false;
    _timer?.cancel();
  }
}
