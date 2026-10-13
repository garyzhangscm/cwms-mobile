import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/updates/update_activity.dart';
import 'package:cwms_mobile/shared/updates/update_activity_interceptor.dart';

class DelayedAdapter implements HttpClientAdapter {
  final pending = Completer<void>();
  final started = Completer<void>();
  int status = 200;
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    started.complete();
    await pending.future;
    return ResponseBody.fromString('{}', status, headers: {
      'content-type': ['application/json']
    });
  }

  void close({bool force = false}) {}
}

void main() {
  test('concurrent requests remain protected until both finish', () async {
    final first = DelayedAdapter();
    final second = DelayedAdapter();
    final a = Dio()..httpClientAdapter = first;
    final b = Dio()..httpClientAdapter = second;
    a.interceptors.add(UpdateActivityInterceptor());
    b.interceptors.add(UpdateActivityInterceptor());
    final one = a.get('https://example.invalid/one');
    final two = b.get('https://example.invalid/two');
    await Future.wait([first.started.future, second.started.future]);
    expect(UpdateActivity.instance.busy, true);
    first.pending.complete();
    await one;
    expect(UpdateActivity.instance.busy, true);
    second.pending.complete();
    await two;
    expect(UpdateActivity.instance.busy, false);
    a.close();
    b.close();
  });
  test('HTTP errors release protection and still reach the caller', () async {
    final adapter = DelayedAdapter()..status = 403;
    final client = Dio()..httpClientAdapter = adapter;
    client.interceptors.add(UpdateActivityInterceptor());
    final request = client.get('https://example.invalid/error');
    await adapter.started.future;
    expect(UpdateActivity.instance.busy, true);
    adapter.pending.complete();
    await expectLater(request, throwsA(isA<DioException>()));
    expect(UpdateActivity.instance.busy, false);
    client.close();
  });
}
