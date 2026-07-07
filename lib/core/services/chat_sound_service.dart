import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'web_eval_stub.dart' if (dart.library.js) 'web_eval_web.dart';

/// Plays a soft, pleasant ping for incoming chat messages.
class ChatSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void playPing() {
    try {
      if (kIsWeb) {
        _playWebPing();
      } else {
        _playMobilePing();
      }
    } catch (e) {
      debugPrint('Error playing chat ping: $e');
    }
  }

  static void playMentionPing() {
    try {
      if (kIsWeb) {
        _playWebMentionPing();
      } else {
        _playMobilePing();
      }
    } catch (e) {
      debugPrint('Error playing mention ping: $e');
    }
  }

  static void _playMobilePing() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/reminder.wav'));
    } catch (e) {
      debugPrint('Error playing mobile chat ping: $e');
    }
  }
}

void _playWebPing() {
  try {
    evalJs(
      """
      (function() {
        try {
          var AudioContext = window.AudioContext || window.webkitAudioContext;
          if (!AudioContext) return;
          var context = new AudioContext();
          
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
            gain.gain.linearRampToValueAtTime(0.28, time + 0.01);
            gain.gain.exponentialRampToValueAtTime(0.001, time + duration);
            
            osc.start(time);
            osc.stop(time + duration);
          }
          
          var now = context.currentTime;
          playTone(1046, now, 0.22);
          playTone(1318, now + 0.14, 0.28);
        } catch (e) {
          console.error("Web audio error:", e);
        }
      })();
      """
    );
  } catch (e) {
    debugPrint('Error playing web chat ping via JS: $e');
  }
}

void _playWebMentionPing() {
  try {
    evalJs(
      """
      (function() {
        try {
          var AudioContext = window.AudioContext || window.webkitAudioContext;
          if (!AudioContext) return;
          var context = new AudioContext();
          
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
            gain.gain.linearRampToValueAtTime(0.4, time + 0.03);
            gain.gain.exponentialRampToValueAtTime(0.01, time + duration);
            
            osc.start(time);
            osc.stop(time + duration);
          }
          
          var now = context.currentTime;
          playTone(660, now, 0.15); // A single sweet E5 chime
        } catch (e) {
          console.error("Web audio error:", e);
        }
      })();
      """
    );
  } catch (e) {
    debugPrint('Error playing web chat ping via JS: $e');
  }
}
