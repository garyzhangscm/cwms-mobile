import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
// Reuse the exact plugin already shipped in the installed Android binaries.
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Uses only the WebView plugin already included in existing Android releases.
/// One local document per app process. No network or additional sound assets.
class WebAudioFailurePlayer {
  static final shared = WebAudioFailurePlayer();
  WebViewController? _controller;
  Future<void>? _preparing;
  final Map<String, Completer<void>> _playing = {};
  int _sequence = 0;

  Future<void> prepare() =>
      _preparing ??= _prepare().catchError((Object error) {
        _preparing = null;
        throw error;
      });

  Future<void> _prepare() async {
    final ready = Completer<void>();
    final controller = WebViewController();
    _controller = controller;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (controller.platform is AndroidWebViewController) {
      await (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    await controller.addJavaScriptChannel('ScanAlert',
        onMessageReceived: (message) {
      try {
        final data = jsonDecode(message.message) as Map<String, dynamic>;
        if (data['type'] == 'ready') {
          if (!ready.isCompleted) ready.complete();
          return;
        }
        final id = data['id'] as String?;
        final result = _playing[id];
        if (result == null || result.isCompleted) return;
        if (data['type'] == 'scheduled' && data['state'] == 'running') {
          result.complete();
        } else {
          result.completeError(StateError('Warning sound unavailable'));
        }
      } catch (_) {
        // Ignore malformed messages; the bounded wait below handles failure.
      }
    });
    await controller.loadHtmlString(document);
    await ready.future.timeout(const Duration(seconds: 5));
  }

  Future<void> play() async {
    await prepare();
    final id = '${++_sequence}';
    final done = Completer<void>();
    _playing[id] = done;
    try {
      // Start listening before invoking JS: completion/error can arrive early.
      final completed = done.future.timeout(const Duration(seconds: 2));
      unawaited(completed.catchError((_) {}));
      await _controller!
          .runJavaScript('window.playFailure(${jsonEncode(id)});');
      await completed;
      // AudioContext's ended callback can be throttled for an unattached view.
      // JS has scheduled 375ms of audio; space warnings using Dart's clock.
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      _playing.remove(id);
    }
  }

  static const document = '''<!doctype html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'">
</head><body><script>
(function () {
  var context = null;
  function send(value) { ScanAlert.postMessage(JSON.stringify(value)); }
  window.playFailure = async function (id) {
    try {
      var Audio = window.AudioContext || window.webkitAudioContext;
      if (!Audio) throw new Error('Unavailable');
      context = context || new Audio();
      await context.resume();
      if (context.state !== 'running') throw new Error('Suspended');
      var start = context.currentTime + 0.015;
      for (var i = 0; i < 2; i++) {
        var oscillator = context.createOscillator();
        var gain = context.createGain();
        var at = start + i * 0.19;
        oscillator.type = 'triangle';
        oscillator.frequency.setValueAtTime(660, at);
        oscillator.frequency.exponentialRampToValueAtTime(330, at + 0.14);
        gain.gain.setValueAtTime(0, at);
        gain.gain.linearRampToValueAtTime(0.35, at + 0.008);
        gain.gain.setValueAtTime(0.35, at + 0.12);
        gain.gain.linearRampToValueAtTime(0, at + 0.16);
        oscillator.connect(gain);
        gain.connect(context.destination);
        oscillator.start(at);
        oscillator.stop(at + 0.17);
        oscillator.onended = (function (tone, volume) {
          return function () { tone.disconnect(); volume.disconnect(); };
        })(oscillator, gain);
      }
      send({type: 'scheduled', id: id, state: context.state});
    } catch (_) { send({type: 'error', id: id}); }
  };
  send({type: 'ready'});
})();
</script></body></html>''';
}
