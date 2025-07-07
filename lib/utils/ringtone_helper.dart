import 'package:just_audio/just_audio.dart';
// import 'package:vibration/vibration.dart';

class RingtoneHelper {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;

  Future<void> start() async {
    if (!_isRinging) {
      _isRinging = true;
      try {
        await _audioPlayer.setAsset('assets/ringtone.mp3');
        _audioPlayer.setLoopMode(LoopMode.one);
        _audioPlayer.play();
      } catch (_) {}
      // if (await Vibration.hasVibrator() ?? false) {
      //   Vibration.vibrate(pattern: [0, 800, 600, 800, 600], repeat: 0);
      // }
    }
  }

  void stop() {
    if (_isRinging) {
      _audioPlayer.stop();
      // Vibration.cancel();
      _isRinging = false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    stop();
  }
}
