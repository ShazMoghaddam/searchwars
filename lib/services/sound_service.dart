import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_stub.dart' if (dart.library.js_interop) 'sound_web.dart';

class SoundService {
  static const _muteKey = 'sound_muted';
  static bool _muted = false;
  static bool get muted => _muted;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_muteKey) ?? false;
  }

  static Future<void> toggleMute() async {
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, _muted);
  }

  static void playCorrect()  => _play(880, 0.18, 'sine');
  static void playWrong()    => _play(200, 0.35, 'sawtooth');
  static void playGameOver() => _play(130, 0.55, 'sawtooth');
  static void playTap()      => _play(640, 0.07, 'sine');
  static void playWin() {
    _play(523, 0.20, 'sine');
    Future.delayed(const Duration(milliseconds: 120), () => _play(659, 0.20, 'sine'));
    Future.delayed(const Duration(milliseconds: 240), () => _play(784, 0.40, 'sine'));
  }

  static void _play(double freq, double dur, String type) {
    if (_muted) return;
    if (!kIsWeb) {
      HapticFeedback.selectionClick();
      return;
    }
    playWebAudio(freq, dur, type);
  }
}
