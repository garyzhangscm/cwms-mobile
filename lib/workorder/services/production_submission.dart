/// Keeps one submission in flight across scanner and button events.
class ProductionSubmission {
  bool busy = false;

  Future<void> run(Future<void> Function() submit) async {
    if (busy) return;
    busy = true;
    try {
      await submit();
    } finally {
      busy = false;
    }
  }
}

/// Checks are independent; wait for both, including when one fails.
Future<String> validateProductionSubmission(
    Future<String> Function() validateLpn,
    Future<void> Function() validateAssignment) async {
  final results = await Future.wait<Object?>([
    validateLpn(),
    validateAssignment(),
  ]);
  return results.first as String;
}
