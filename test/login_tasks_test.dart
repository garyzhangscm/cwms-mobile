import 'dart:async';

import 'package:cwms_mobile/auth/services/login_tasks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings overlap workstation reads but completion waits for RF update',
      () async {
    final rf = Completer<int>();
    final location = Completer<int>();
    final config = Completer<String>();
    final version = Completer<int>();
    final changed = Completer<String>();
    final started = <String>[];
    var updateStarted = false;
    var loginReady = false;
    Future<T> load<T>(String name, Completer<T> response) {
      started.add(name);
      return response.future;
    }

    final ready = runLoginTasks(() async {
      final ids = await runLoginTasks(
          () => load('rf', rf), () => load('location', location));
      expect(ids, (7, 12));
      updateStarted = true;
      return await changed.future;
    }, () => runLoginTasks(
        () => load('configuration', config), () => load('version', version)));
    final observed = ready.then((result) {
      loginReady = true;
      return result;
    });
    expect(started, ['rf', 'location', 'configuration', 'version']);
    config.complete('Main');
    version.complete(9);
    rf.complete(7);
    await Future<void>.delayed(Duration.zero);
    expect(updateStarted, isFalse);
    location.complete(12);
    await Future<void>.delayed(Duration.zero);
    expect(updateStarted, isTrue);
    expect(loginReady, isFalse);
    changed.complete('RF updated');
    expect(await observed, ('RF updated', ('Main', 9)));
  });

  test('independent reads start before either network response arrives',
      () async {
    final rf = Completer<int>();
    final location = Completer<String>();
    final started = <String>[];
    final result = runLoginTasks(() {
      started.add('rf');
      return rf.future;
    }, () {
      started.add('location');
      return location.future;
    });
    expect(started, ['rf', 'location']);
    // Responses can finish in either order without swapping RF and location.
    location.complete('C5');
    rf.complete(7);
    expect(await result, (7, 'C5'));
  });

  test('failed read waits for other read before permitting a retry', () async {
    final location = Completer<bool>();
    var settled = false;
    final result = runLoginTasks<bool, bool>(
        () => Future.error(StateError('RF unavailable')),
        () => location.future);
    final handled =
        result.then<void>((_) => settled = true, onError: (Object e) {
      expect(e, isA<StateError>());
      settled = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse);
    location.complete(true);
    await handled;
    expect(settled, isTrue);
  });

  test('invalid workstation and missing optional settings remain explicit',
      () async {
    expect(await runLoginTasks(() async => false, () async => true),
        (false, true));
    expect(
        await runLoginTasks<String?, int?>(() async => null, () async => null),
        (null, null));
  });
}
