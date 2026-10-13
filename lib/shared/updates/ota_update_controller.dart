import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class OtaPolicy {
  const OtaPolicy({this.minimumPatch = 0, this.message = ''});
  final int minimumPatch;
  final String message;
  factory OtaPolicy.fromJson(Map<String, dynamic> json, String release) {
    if (json['releaseVersion'] != release) return const OtaPolicy();
    final minimum = json['minimumPatch'];
    if (minimum is! int || minimum < 0)
      throw const FormatException('Invalid minimum patch');
    return OtaPolicy(
        minimumPatch: minimum,
        message: json['message'] is String ? json['message'] as String : '');
  }
}

abstract class OtaGateway {
  bool get available;
  Future<int> currentPatch();
  Future<int> nextPatch();
  Future<void> download();
}

class ShorebirdGateway implements OtaGateway {
  final _updater = ShorebirdUpdater();
  bool get available => _updater.isAvailable;
  Future<int> currentPatch() async =>
      (await _updater.readCurrentPatch())?.number ?? 0;
  Future<int> nextPatch() async =>
      (await _updater.readNextPatch())?.number ?? 0;
  Future<void> download() async {
    if (await _updater.checkForUpdate() == UpdateStatus.outdated)
      await _updater.update();
  }
}

class OtaUpdateController extends ChangeNotifier {
  OtaUpdateController({required this.gateway, required this.loadPolicy});
  final OtaGateway gateway;
  final Future<OtaPolicy> Function() loadPolicy;
  int current = 0;
  int next = 0;
  OtaPolicy policy = const OtaPolicy();
  bool checking = false;
  bool initialized = false;
  String? error;
  DateTime? deferredUntil;
  bool get ready => next > current;
  // Never lock staff out before the required patch is actually downloaded.
  // A rollback (next < current) must not be interpreted as an upgrade.
  bool get mandatory =>
      ready && current < policy.minimumPatch && next >= policy.minimumPatch;
  bool get visible =>
      ready &&
      (mandatory ||
          deferredUntil == null ||
          DateTime.now().isAfter(deferredUntil!));
  void defer() {
    if (!mandatory) {
      deferredUntil = DateTime.now().add(const Duration(minutes: 30));
      notifyListeners();
    }
  }

  Future<void> check() async {
    if (checking || !gateway.available) return;
    checking = true;
    error = null;
    notifyListeners();
    try {
      current = await gateway.currentPatch();
      initialized = true;
      next = await gateway.nextPatch();
      notifyListeners();
      // Failure to reach MES must not prevent Shorebird downloading a patch.
      try {
        policy = await loadPolicy();
      } catch (_) {/* retain last valid policy */}
      await gateway.download();
      next = await gateway.nextPatch();
    } catch (_) {
      error = 'Unable to check for updates. We will retry when connected.';
    } finally {
      checking = false;
      notifyListeners();
    }
  }
}
