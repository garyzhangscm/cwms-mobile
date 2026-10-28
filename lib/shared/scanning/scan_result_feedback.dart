import 'scan_feedback.dart';

/// Kept on the operation record, not on a rebuilding list tile.
class ScanResultFeedback {
  ScanAttempt? attempt;
  bool _wasRunning = false;
  bool get pending => attempt?.uncertain == true;
  void update(bool running, bool success, String? message) {
    if (running && !_wasRunning) attempt = ScanFeedback.current;
    _wasRunning = running;
    if (!running &&
        !success &&
        (message?.trim().isNotEmpty ?? false) &&
        attempt != null) ScanFeedback.fail(attempt!);
  }
}
