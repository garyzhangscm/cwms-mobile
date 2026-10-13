import 'package:flutter/foundation.dart';

/// Includes whole business actions, not just the final HTTP request.
class UpdateActivity extends ChangeNotifier {
  static final instance = UpdateActivity();
  int _active = 0;
  bool get busy => _active > 0;
  void begin() {
    _active++;
    notifyListeners();
  }

  void end() {
    if (_active > 0) _active--;
    notifyListeners();
  }

  Future<T> run<T>(Future<T> Function() action) async {
    begin();
    try {
      return await action();
    } finally {
      end();
    }
  }
}
