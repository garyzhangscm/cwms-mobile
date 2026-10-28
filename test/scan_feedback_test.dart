import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';
import 'package:cwms_mobile/shared/scanning/scan_request_interceptor.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_queue.dart';

class _ErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late int alarms;
  Future<void> flush() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    alarms = 0;
    ScanFeedback.failurePlayer = () async {
      alarms++;
    };
  });
  tearDown(() async {
    await flush();
    ScanFeedback.failurePlayer = null;
  });
  test('scan requests have bounded waits; ordinary requests are unchanged',
      () async {
    final interceptor = ScanRequestInterceptor();
    final ordinary = RequestOptions(path: 'ordinary');
    interceptor.onRequest(ordinary, RequestInterceptorHandler());
    expect(ordinary.receiveTimeout, isNull);
    await ScanFeedback.run(() async {
      final scan = RequestOptions(path: 'scan');
      interceptor.onRequest(scan, RequestInterceptorHandler());
      expect(scan.connectTimeout, const Duration(seconds: 8));
      expect(scan.receiveTimeout, const Duration(seconds: 45));
      final explicit = RequestOptions(
          path: 'upload', receiveTimeout: const Duration(minutes: 2));
      interceptor.onRequest(explicit, RequestInterceptorHandler());
      expect(explicit.receiveTimeout, const Duration(minutes: 2));
    });
  });
  test('ten successful scans stay silent', () async {
    for (var i = 0; i < 10; i++) {
      await ScanFeedback.run(() async {
        ScanFeedback.confirmed();
      });
    }
    await flush();
    expect(alarms, 0);
  });
  test('same attempt reports once, user rescan is a new attempt', () async {
    await ScanFeedback.run(() async {
      ScanFeedback.reportError('not found');
      ScanFeedback.reportError('not found again');
    });
    await flush();
    expect(alarms, 1);
    await ScanFeedback.run(() async {
      ScanFeedback.reportError('not found');
    });
    await flush();
    expect(alarms, 2);
  });
  test('distinct simultaneous failures each alert, serial playback', () async {
    final gate = Completer<void>();
    var active = 0, maxActive = 0;
    ScanFeedback.failurePlayer = () async {
      alarms++;
      active++;
      if (active > maxActive) maxActive = active;
      await gate.future;
      active--;
    };
    await Future.wait(List.generate(
        3,
        (_) => ScanFeedback.run(() async {
              ScanFeedback.reportError('bad LPN');
            }, fresh: true)));
    await flush();
    expect(alarms, 1);
    gate.complete();
    await flush();
    expect(alarms, 3);
    expect(maxActive, 1);
  });
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError
  ]) {
    test('$type is pending, never a rejection tone', () async {
      await ScanFeedback.run(() async {
        final e = DioException(
            requestOptions: RequestOptions(path: 'scan'), type: type);
        expect(ScanFeedback.reportError('network error', error: e), isTrue);
        ScanFeedback.reportError('the same timeout');
      });
      await flush();
      expect(alarms, 0);
    });
  }
  test('HTTP timeout is retained across service wrapping the exception',
      () async {
    await ScanFeedback.run(() async {
      final request = RequestOptions(path: 'scan');
      final interceptor = ScanRequestInterceptor();
      interceptor.onRequest(request, RequestInterceptorHandler());
      interceptor.onError(
          DioException(
              requestOptions: request, type: DioExceptionType.receiveTimeout),
          _ErrorHandler());
      expect(ScanFeedback.reportError('wrapped request error'), isTrue);
    });
    await flush();
    expect(alarms, 0);
  });
  test('record keeps its attempt after callback leaves its original zone',
      () async {
    late InventoryDepositRequest row;
    await ScanFeedback.run(() async {
      row = InventoryDepositRequest()..requestInProcess = true;
    });
    row.requestResult = false;
    row.requestInProcess = false;
    row.result = 'No matching LPN';
    row.result = 'No matching LPN';
    row.requestInProcess = false;
    await flush();
    expect(alarms, 1);
  });
  test(
      'timeout row is pending and silent; known rejection is red-state failure',
      () async {
    late InventoryDepositRequest row;
    await ScanFeedback.run(() async {
      row = InventoryDepositRequest()..requestInProcess = true;
      ScanFeedback.current!.uncertain = true;
    });
    row.requestInProcess = false;
    row.result = 'Timed out';
    await flush();
    expect(row.pendingConfirmation, isTrue);
    expect(alarms, 0);
  });
  test('refresh errors after successful commit do not alarm', () async {
    await ScanFeedback.run(() async {
      ScanFeedback.confirmed();
      ScanFeedback.reportError('Could not refresh remaining');
    });
    await flush();
    expect(alarms, 0);
  });
  test('audio exceptions do not change the business result', () async {
    ScanFeedback.failurePlayer = () async {
      throw StateError('no audio device');
    };
    await ScanFeedback.run(() async {
      ScanFeedback.reportError('bad');
    });
    await flush();
  });
  test(
      'queue persists alert flag and does not repeat on reload; explicit retry alerts again',
      () async {
    String? saved;
    var alerts = 0;
    PutawaySyncQueue queue() => PutawaySyncQueue(
        read: () async => saved,
        write: (s) async {
          saved = s;
        },
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async {
          throw PutawaySyncFailure('Not found');
        },
        onFailure: (_, __) async {
          alerts++;
        });
    final q = queue();
    await q.initialize(startTimer: false);
    await q.add('TEST-LPN');
    await q.kick();
    await flush();
    expect(alerts, 1);
    expect((jsonDecode(saved!) as List).single['failureAlerted'], isTrue);
    await q.kick();
    expect(alerts, 1);
    q.dispose();
    final restored = queue();
    await restored.initialize(startTimer: false);
    await restored.kick();
    await flush();
    expect(alerts, 1);
    await restored.add('TEST-LPN');
    await restored.kick();
    await flush();
    expect(alerts, 2);
    restored.dispose();
  });
  test('pending queue scans stay saved without an alarm', () async {
    String? saved;
    var alerts = 0;
    final q = PutawaySyncQueue(
        read: () async => saved,
        write: (s) async {
          saved = s;
        },
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async {
          throw PutawaySyncFailure('Unknown result', retryable: true);
        },
        onFailure: (_, __) async {
          alerts++;
        });
    await q.initialize(startTimer: false);
    await q.add('TEST-LPN');
    await q.kick();
    await flush();
    expect(q.entries.single.state, 'pending');
    expect(q.connection, 'offline');
    expect(alerts, 0);
    expect(saved, contains('TEST-LPN'));
    q.dispose();
  });
  test('slow speaker does not delay processing multiple failed LPNs', () async {
    final gate = Completer<void>();
    var alerts = 0;
    final q = PutawaySyncQueue(
        read: () async => null,
        write: (_) async {},
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async {
          throw PutawaySyncFailure('Bad LPN');
        },
        onFailure: (_, __) async {
          alerts++;
          await gate.future;
        });
    await q.initialize(startTimer: false);
    await q.add('TEST-1');
    await q.add('TEST-2');
    await q.kick();
    await flush();
    expect(q.entries.every((e) => e.state == 'failed'), isTrue);
    expect(alerts, 2);
    gate.complete();
    q.dispose();
  });
}
