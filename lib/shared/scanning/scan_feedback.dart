import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'web_audio_failure_player.dart';

/// A scan attempt, not an HTTP request: automatic retries share this identity.
class ScanAttempt {
  ScanAttempt(this.id);
  final String id;
  bool uncertain = false;
  bool alerted = false;
  bool completed = false;
}

class ScanFeedback {
  static final Object _zoneKey = Object();
  static int _sequence = 0;
  static Future<void> _sounds = Future.value();
  static ScanAttempt? get current => Zone.current[_zoneKey] as ScanAttempt?;
  @visibleForTesting
  static Future<void> Function()? failurePlayer;

  static String nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';

  static Future<T> run<T>(Future<T> Function() action, {bool fresh = false}) {
    if (current != null && !fresh) return action();
    return runZoned(action, zoneValues: {_zoneKey: ScanAttempt(nextId())});
  }

  static bool isUncertain(Object error) =>
      error is DioException &&
      (error.type != DioExceptionType.badResponse ||
          error.response?.statusCode == 401 ||
          error.response?.statusCode == 408 ||
          (error.response?.statusCode ?? 0) >= 500);

  /// Returns true only for an unknown result; never turns a timeout into failure.
  static bool reportError(String message, {Object? error}) {
    final attempt = current;
    if (attempt == null || attempt.completed) return false;
    if (error != null && isUncertain(error)) attempt.uncertain = true;
    if (attempt.uncertain) return true;
    fail(attempt);
    return false;
  }

  static void fail(ScanAttempt attempt) {
    if (attempt.alerted || attempt.completed || attempt.uncertain) return;
    attempt.alerted = true;
    unawaited(playFailure());
  }

  /// Called at the business acknowledgement, before ancillary list refreshes.
  static void confirmed() {
    current?.completed = true;
  }

  static Future<void> playFailure() {
    final next = _sounds.catchError((_) {}).then((_) async {
      try {
        final player = failurePlayer;
        if (player != null) {
          await player();
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          await WebAudioFailurePlayer.shared.play();
        }
      } catch (_) {
        // Audio must never change a business result or cause a second submission.
      }
    });
    _sounds = next;
    return next;
  }
}
