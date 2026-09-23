import 'package:flutter/services.dart';

class LpnOcrService {
  static const MethodChannel _channel = MethodChannel('cwms_mobile/vision_ocr');

  static Future<List<String>> recognizeLpnCandidates(String imagePath) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'recognizeText',
      {'path': imagePath},
    );
    if (result == null) return const [];

    final values = <String>{};
    for (final item in result) {
      final text = item is Map ? item['text']?.toString() : item?.toString();
      final normalized = normalizeCandidate(text ?? '');
      if (normalized != null) values.add(normalized);
    }
    return values.toList();
  }

  static String? normalizeCandidate(String value) {
    final cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (!RegExp(r'^[LR][A-Z0-9]{5,}$').hasMatch(cleaned)) return null;
    return cleaned;
  }
}
