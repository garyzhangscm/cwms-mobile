import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_queue.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_gateway.dart';

void main() {
  test('offline scans survive restart and synchronize when server recovers',
      () async {
    String? saved;
    var online = false;
    final sent = <String>[];
    PutawaySyncQueue create() => PutawaySyncQueue(
        read: () async => saved,
        write: (v) async {
          saved = v;
        },
        sessionMatches: () => true,
        probe: () async {
          if (!online) throw PutawaySyncFailure('offline', retryable: true);
          return 0;
        },
        synchronize: (lpn) async {
          sent.add(lpn);
          return PutawaySyncResult(5, 'ITEM');
        });
    var queue = create();
    await queue.initialize(startTimer: false);
    await Future.wait([queue.add('LPN1'), queue.add('LPN2')]);
    await queue.kick();
    expect(queue.pendingCount, 2);
    expect(queue.connection, 'offline');
    expect(sent, isEmpty);
    queue.dispose();
    queue = create();
    await queue.initialize(startTimer: false);
    online = true;
    await queue.kick();
    expect(sent, ['LPN1', 'LPN2']);
    expect(queue.pendingCount, 0);
    expect(queue.entries.every((e) => e.state == 'completed'), true);
    queue.dispose();
  });
  test('actual timer resumes saved scans without scanning again', () async {
    var online = false;
    var sent = 0;
    final queue = PutawaySyncQueue(
        read: () async => null,
        write: (_) async {},
        sessionMatches: () => true,
        probe: () async {
          if (!online) throw PutawaySyncFailure('offline', retryable: true);
          return 0;
        },
        synchronize: (_) async {
          sent++;
          return PutawaySyncResult(1, 'I');
        });
    await queue.initialize();
    await queue.add('LPN');
    await queue.kick();
    online = true;
    await Future<void>.delayed(const Duration(milliseconds: 5200));
    expect(sent, 1);
    queue.dispose();
  });
  test('login expiration pauses without losing scans; same session resumes',
      () async {
    String? saved;
    var loggedIn = true;
    var expire = true;
    var sent = 0;
    final queue = PutawaySyncQueue(
        read: () async => saved,
        write: (v) async {
          saved = v;
        },
        sessionMatches: () => loggedIn,
        probe: () async {
          if (expire) throw PutawaySyncFailure('expired', loginRequired: true);
          return 0;
        },
        synchronize: (_) async {
          sent++;
          return PutawaySyncResult(1, 'I');
        });
    await queue.initialize(startTimer: false);
    await queue.add('LPN');
    await queue.kick();
    expect(queue.connection, 'login');
    expect(queue.pendingCount, 1);
    expect(jsonDecode(saved!).length, 1);
    loggedIn = false;
    expire = false;
    await queue.kick();
    expect(sent, 0);
    loggedIn = true;
    await queue.kick();
    expect(sent, 1);
    queue.dispose();
  });
  test('repeated kicks and duplicate scans do not send twice', () async {
    final gate = Completer<void>();
    var sent = 0;
    final queue = PutawaySyncQueue(
        read: () async => null,
        write: (_) async {},
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async {
          sent++;
          await gate.future;
          return PutawaySyncResult(1, 'I');
        });
    await queue.initialize(startTimer: false);
    await queue.add('LPN');
    await queue.add('LPN');
    final work = queue.kick();
    await Future<void>.delayed(Duration.zero);
    await queue.kick();
    gate.complete();
    await work;
    await queue.kick();
    expect(sent, 1);
    expect(queue.entries.length, 1);
    queue.dispose();
  });
  test(
      'business failures allow explicit retry; clearing completed retains pending',
      () async {
    var fail = true;
    final queue = PutawaySyncQueue(
        read: () async => null,
        write: (_) async {},
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (lpn) async {
          if (lpn == 'BAD' && fail) throw PutawaySyncFailure('Not found');
          return PutawaySyncResult(1, 'I');
        });
    await queue.initialize(startTimer: false);
    await queue.add('GOOD');
    await queue.add('BAD');
    await queue.kick();
    expect(queue.entries.first.state, 'failed');
    await queue.add('PENDING');
    await queue.clearCompleted();
    expect(queue.entries.map((e) => e.lpn), ['PENDING', 'BAD']);
    fail = false;
    await queue.add('BAD');
    await queue.kick();
    expect(queue.pendingCount, 0);
    queue.dispose();
  });
  test(
      'interrupted syncing restores pending and storage failure is not acknowledged',
      () async {
    final queue = PutawaySyncQueue(
        read: () async => jsonEncode([
              {'lpn': 'OLD', 'state': 'syncing'}
            ]),
        write: (_) async {
          throw StateError('disk');
        },
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async => PutawaySyncResult(1, 'I'));
    await queue.initialize(startTimer: false);
    expect(queue.entries.single.state, 'pending');
    await expectLater(queue.add('NEW'), throwsStateError);
    expect(queue.entries.map((e) => e.lpn), ['OLD']);
    queue.dispose();
  });
  test(
      'uncertain successful move is reconciled before retrying; remaining records continue',
      () async {
    final gateway = FakeGateway();
    await expectLater(
        gateway.synchronize('LPN'), throwsA(isA<PutawaySyncFailure>()));
    final result = await gateway.synchronize('LPN');
    expect(gateway.moves, [1, 2]);
    expect(result.quantity, 12);
    expect(result.newRfRecords, 1);
  });
  test(
      'persisted move checkpoint prevents moving inventory back from another location',
      () async {
    final gateway = FakeGateway();
    final scan = PutawayScan('LPN');
    String? saved;
    await expectLater(
        gateway.synchronize('LPN', scan: scan, saveCheckpoint: () async {
          saved = jsonEncode(scan.toJson());
        }),
        throwsA(isA<PutawaySyncFailure>()));
    gateway.locations[1] = 200;
    final restored =
        PutawayScan.fromJson(Map<String, dynamic>.from(jsonDecode(saved!)));
    await expectLater(
        gateway.synchronize('LPN', scan: restored, saveCheckpoint: () async {}),
        throwsA(isA<PutawaySyncFailure>()
            .having((e) => e.retryable, 'retryable', false)));
    expect(gateway.moves, [1]);
  });
}

class FakeGateway extends PutawaySyncGateway {
  FakeGateway() : super('http://test', 1, 1, 'RF1', 'user');
  final locations = {1: 10, 2: 10};
  final moves = <int>[];
  bool uncertain = true;
  @override
  Future<dynamic> request(String method, String path,
      {Map<String, dynamic>? query, dynamic data}) async {
    if (path == '/inventory/inventories')
      return locations.entries
          .map((e) =>
              {'id': e.key, 'lpn': 'LPN', 'quantity': 6, 'locationId': e.value})
          .toList();
    if (path == '/layout/locations')
      return [
        {'id': 99, 'name': 'RF1'}
      ];
    final id = query!['inventoryId'] as int;
    moves.add(id);
    locations[id] = 99;
    if (uncertain) {
      uncertain = false;
      throw PutawaySyncFailure('reply lost', retryable: true);
    }
    return [];
  }
}
