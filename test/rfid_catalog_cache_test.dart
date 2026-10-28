import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/workorder/models/rfid_catalog_cache.dart';
import 'package:cwms_mobile/workorder/models/rfid_pallet.dart';

void main() {
  test(
      'Expired mapping remains visible during refresh and after failure, scoped to login',
      () async {
    var now = DateTime(2026);
    final cache = RfidCatalogCache(now: () => now);
    final old = RfidCatalog([]);
    await cache.load('A', () async => old);
    now = now.add(const Duration(minutes: 3));
    final pending = Completer<RfidCatalog>();
    final refresh = cache.load('A', () => pending.future);
    expect(cache.peek('A'), same(old));
    expect(cache.peek('B'), isNull);
    final failed = expectLater(refresh, throwsStateError);
    pending.completeError(StateError('offline'));
    await failed;
    expect(cache.peek('A'), same(old));
    final updated = RfidCatalog([]);
    await cache.load('A', () async => updated);
    expect(cache.peek('A'), same(updated));
    await cache.load('B', () async => RfidCatalog([]));
    expect(cache.peek('A'), isNull);
  });
  test(
      'Prefetch and entry share request; fresh entries avoid network; expiry reloads',
      () async {
    var now = DateTime(2026);
    final cache = RfidCatalogCache(now: () => now);
    final pending = Completer<RfidCatalog>();
    var calls = 0;
    Future<RfidCatalog> fetch() {
      calls++;
      return pending.future;
    }

    final a = cache.load('A', fetch);
    final b = cache.load('A', fetch);
    expect(identical(a, b), true);
    final catalog = RfidCatalog([]);
    pending.complete(catalog);
    expect(await a, same(catalog));
    expect(await cache.load('A', fetch), same(catalog));
    expect(calls, 1);
    now = now.add(const Duration(minutes: 2));
    await cache.load('A', fetch);
    expect(calls, 2);
    await cache.load('A', fetch, forceRefresh: true);
    expect(calls, 3);
  });
  test('Late result from another login cannot populate current cache',
      () async {
    final cache = RfidCatalogCache();
    final pending = Completer<RfidCatalog>();
    final a = cache.load('A', () => pending.future);
    final rejected = expectLater(a, throwsStateError);
    final b = RfidCatalog([]);
    expect(await cache.load('B', () async => b), same(b));
    pending.complete(RfidCatalog([]));
    await rejected;
    expect(
        await cache.load('B', () async => throw StateError('must not fetch')),
        same(b));
    var called = false;
    await cache.load('A', () async {
      called = true;
      return RfidCatalog([]);
    });
    expect(called, true);
  });
  test('Failure is not cached and explicit refresh replaces old mappings',
      () async {
    final cache = RfidCatalogCache();
    await expectLater(cache.load('A', () async => throw StateError('offline')),
        throwsStateError);
    final old = RfidCatalog([]);
    expect(await cache.load('A', () async => old), same(old));
    final updated = RfidCatalog([]);
    expect(await cache.load('A', () async => updated, forceRefresh: true),
        same(updated));
    expect(await cache.load('A', () async => old), same(updated));
  });
}
