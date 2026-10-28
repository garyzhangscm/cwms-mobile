import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_queue.dart';

void main() {
  test('removing a rejected typo persists locally without any server operation',
      () async {
    String? saved = jsonEncode([
      {'lpn': 'TYPO', 'state': 'failed'},
      {'lpn': 'WAIT', 'state': 'pending'}
    ]);
    var network = 0;
    PutawaySyncQueue make() => PutawaySyncQueue(
        read: () async => saved,
        write: (v) async {
          saved = v;
        },
        sessionMatches: () => true,
        probe: () async {
          network++;
          return 0;
        },
        synchronize: (_) async {
          network++;
          return PutawaySyncResult(1, 'I');
        });
    final q = make();
    await q.initialize(startTimer: false);
    expect(q.canRemoveFailed('TYPO'), true);
    expect(await q.removeFailed('TYPO'), true);
    expect(await q.removeFailed('TYPO'), false);
    expect(q.entries.map((e) => e.lpn), ['WAIT']);
    final restored = make();
    await restored.initialize(startTimer: false);
    expect(restored.entries.map((e) => e.lpn), ['WAIT']);
    expect(network, 0);
    q.dispose();
    restored.dispose();
  });
  test('pending completed and possibly moved records cannot be removed',
      () async {
    final q = PutawaySyncQueue(
        read: () async => jsonEncode([
              {'lpn': 'WAIT', 'state': 'pending'},
              {'lpn': 'DONE', 'state': 'completed'},
              {
                'lpn': 'PARTIAL',
                'state': 'failed',
                'origins': {'1': 5}
              }
            ]),
        write: (_) async {},
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async => PutawaySyncResult(1, 'I'));
    await q.initialize(startTimer: false);
    for (final lpn in ['WAIT', 'DONE', 'PARTIAL']) {
      expect(q.canRemoveFailed(lpn), false);
      expect(await q.removeFailed(lpn), false);
    }
    expect(q.entries.length, 3);
    q.dispose();
  });
  test('failed local save restores record for retry instead of losing it',
      () async {
    final q = PutawaySyncQueue(
        read: () async => jsonEncode([
              {'lpn': 'TYPO', 'state': 'failed'}
            ]),
        write: (_) async {
          throw StateError('disk full');
        },
        sessionMatches: () => true,
        probe: () async => 0,
        synchronize: (_) async => PutawaySyncResult(1, 'I'));
    await q.initialize(startTimer: false);
    await expectLater(q.removeFailed('TYPO'), throwsStateError);
    expect(q.entries.single.lpn, 'TYPO');
    expect(q.canRemoveFailed('TYPO'), true);
    q.dispose();
  });
}
