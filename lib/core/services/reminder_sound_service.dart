import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'web_eval_stub.dart' if (dart.library.js) 'web_eval_web.dart';

/// Service to handle reminder sound notifications across all platforms.
class ReminderSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void playBeep() {
    try {
      if (kIsWeb) {
        _playWebBeep();
      } else {
        _playMobileBeep();
      }
    } catch (e) {
      debugPrint('Error playing reminder beep: $e');
    }
  }

  static void _playMobileBeep() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/reminder.wav'));
    } catch (e) {
      debugPrint('Error playing mobile reminder sound: $e');
    }
  }
}

void _playWebBeep() {
  try {
    evalJs(
      """
      (function() {
        try {
          var AudioContext = window.AudioContext || window.webkitAudioContext;
          if (!AudioContext) return;
          var context = new AudioContext();
          
          // Resume audio context if suspended by browser autoplay policy
          if (context.state === 'suspended') {
            context.resume();
          }
          
          function playTone(freq, time, duration) {
            var osc = context.createOscillator();
            var gain = context.createGain();
            osc.connect(gain);
            gain.connect(context.destination);
            
            osc.type = 'sine';
            osc.frequency.value = freq;
            
            gain.gain.setValueAtTime(0, time);
            gain.gain.linearRampToValueAtTime(0.5, time + 0.05);
            gain.gain.exponentialRampToValueAtTime(0.01, time + duration);
            
            osc.start(time);
            osc.stop(time + duration);
          }
          
          var now = context.currentTime;
          playTone(880, now, 0.25);
          playTone(1109.73, now + 0.15, 0.4);
        } catch (e) {
          console.error("Web audio error:", e);
        }
      })();
      """
    );
  } catch (e) {
    debugPrint('Error playing web reminder sound via JS: $e');
  }
}
