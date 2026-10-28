import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:cwms_mobile/shared/scanning/web_audio_failure_player.dart';
import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';

class FakeAudioPlatform extends WebViewPlatform {
  int created = 0;
  final List<FakeAudioController> controllers = [];
  bool reject = false;
  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    created++;
    final c = FakeAudioController(params, this);
    controllers.add(c);
    return c;
  }
}

class FakeAudioController extends PlatformWebViewController {
  FakeAudioController(super.params, this.owner) : super.implementation();
  final FakeAudioPlatform owner;
  JavaScriptChannelParams? channel;
  int loads = 0, plays = 0;
  void send(Map<String, dynamic> value) =>
      channel!.onMessageReceived(JavaScriptMessage(message: jsonEncode(value)));
  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    channel = params;
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    loads++;
    send({'type': 'ready'});
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    plays++;
    final id = jsonDecode(javaScript.substring(
        javaScript.indexOf('(') + 1, javaScript.lastIndexOf(')')));
    send({
      'type': owner.reject ? 'error' : 'scheduled',
      'id': id,
      'state': owner.reject ? 'suspended' : 'running'
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAudioPlatform platform;
  setUp(() {
    platform = FakeAudioPlatform();
    WebViewPlatform.instance = platform;
  });
  tearDown(() {
    ScanFeedback.failurePlayer = null;
  });
  test('reuses one offline WebView across successive warning sounds', () async {
    final player = WebAudioFailurePlayer();
    await player.play();
    await player.play();
    await player.play();
    expect(platform.created, 1);
    expect(platform.controllers.single.loads, 1);
    expect(platform.controllers.single.plays, 3);
  });
  test('success and pending stay silent, separate rejections alert once each',
      () async {
    final player = WebAudioFailurePlayer();
    ScanFeedback.failurePlayer = player.play;
    for (var i = 0; i < 10; i++) {
      await ScanFeedback.run(() async {
        ScanFeedback.confirmed();
      }, fresh: true);
    }
    await ScanFeedback.run(() async {
      ScanFeedback.current!.uncertain = true;
      ScanFeedback.reportError('pending');
    }, fresh: true);
    expect(platform.created, 0);
    for (var i = 0; i < 3; i++) {
      await ScanFeedback.run(() async {
        ScanFeedback.reportError('rejected');
        ScanFeedback.reportError('same rejection');
      }, fresh: true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(platform.created, 1);
    expect(platform.controllers.single.plays, 3);
  });
  test(
      'blocked playback reports failure instead of pretending the sound played',
      () async {
    platform.reject = true;
    await expectLater(WebAudioFailurePlayer().play(), throwsStateError);
  });
  test('page preparation is shared if several warnings arrive together',
      () async {
    final player = WebAudioFailurePlayer();
    await Future.wait([player.prepare(), player.prepare(), player.prepare()]);
    expect(platform.created, 1);
    expect(platform.controllers.single.loads, 1);
  });
}
