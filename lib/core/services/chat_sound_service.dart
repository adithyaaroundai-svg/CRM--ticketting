// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Plays a soft, pleasant ping for incoming chat messages.
class ChatSoundService {
  static void playPing() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            var AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            var ctx = new AudioContext();

            function tone(freq, start, dur, gainVal, type) {
              var osc = ctx.createOscillator();
              var g   = ctx.createGain();
              osc.connect(g);
              g.connect(ctx.destination);
              osc.type = type || 'sine';
              osc.frequency.setValueAtTime(freq, start);
              g.gain.setValueAtTime(0, start);
              g.gain.linearRampToValueAtTime(gainVal, start + 0.01);
              g.gain.exponentialRampToValueAtTime(0.001, start + dur);
              osc.start(start);
              osc.stop(start + dur);
            }

            var now = ctx.currentTime;
            // Two soft ascending tones — gentle "ding ding"
            tone(1046, now,        0.22, 0.28, 'sine');
            tone(1318, now + 0.14, 0.28, 0.22, 'sine');
          } catch(e) {}
        })();
        ''',
      ]);
    } catch (_) {
      // Silently fail
    }
  }
}
