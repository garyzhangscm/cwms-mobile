import 'package:flutter/foundation.dart';

/// Start independent login reads together and settle both before moving on.
/// Waiting for both also prevents a failed attempt leaving late requests that
/// could interfere with the next account or workstation.
Future<(A, B)> runLoginTasks<A, B>(
    Future<A> Function() first, Future<B> Function() second) async {
  final values = await Future.wait<Object?>([
    Future<A>.sync(first).then<Object?>((value) => value),
    Future<B>.sync(second).then<Object?>((value) => value),
  ]);
  return (values[0] as A, values[1] as B);
}

/// Log durations only: credentials, tokens and response bodies are excluded.
Future<T> measureLoginStep<T>(String stage, Future<T> Function() action) async {
  final clock = Stopwatch()..start();
  try {
    return await action();
  } finally {
    debugPrint('Login timing: $stage ${clock.elapsedMilliseconds} ms');
  }
}
