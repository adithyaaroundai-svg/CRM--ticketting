// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Plays a short notification beep using the Web Audio API.
/// Works in all modern browsers without any asset files.
class ReminderSoundService {
  static void playBeep() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            var AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            var ctx = new AudioContext();

            function beep(freq, startTime, duration, gain) {
              var osc = ctx.createOscillator();
              var gainNode = ctx.createGain();
              osc.connect(gainNode);
              gainNode.connect(ctx.destination);
              osc.type = 'sine';
              osc.frequency.setValueAtTime(freq, startTime);
              gainNode.gain.setValueAtTime(gain, startTime);
              gainNode.gain.exponentialRampToValueAtTime(0.001, startTime + duration);
              osc.start(startTime);
              osc.stop(startTime + duration);
            }

            var now = ctx.currentTime;
            beep(880, now,        0.15, 0.4);
            beep(1100, now + 0.18, 0.15, 0.4);
            beep(1320, now + 0.36, 0.25, 0.5);
          } catch(e) {}
        })();
        ''',
      ]);
    } catch (_) {
      // Silently fail if Web Audio API is unavailable
    }
  }
}
