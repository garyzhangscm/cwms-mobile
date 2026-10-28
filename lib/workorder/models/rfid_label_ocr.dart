import 'rfid_check.dart';

/// Only complete numeric runs: never guess O/0, repair check digits, or join lines.
List<String> labelUpcCandidates(Iterable<String> lines) {
  final found = <String, String>{};
  for (final line in lines) {
    for (final match
        in RegExp(r'(?<![A-Za-z0-9])[0-9](?:[0-9 \t-]*[0-9])?(?![A-Za-z0-9])')
            .allMatches(line)) {
      final value = match.group(0)!.replaceAll(RegExp(r'[ \t-]'), '');
      try {
        found.putIfAbsent(normalizeGtin(value), () => value);
      } on FormatException {
        /* Uncertain OCR must be reviewed, not corrected silently. */
      }
    }
  }
  return found.values.toList();
}
