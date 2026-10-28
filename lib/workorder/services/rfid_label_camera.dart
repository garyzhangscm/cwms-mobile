import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/rfid_label_ocr.dart';

class LabelPhoto {
  const LabelPhoto(this.bytes, this.candidates);
  final Uint8List bytes;
  final List<String> candidates;
}

Future<LabelPhoto?> captureRfidLabel() async {
  final image = await ImagePicker()
      .pickImage(source: ImageSource.camera, imageQuality: 95, maxWidth: 2400);
  if (image == null) return null;
  try {
    final bytes = await image.readAsBytes();
    final result = await const MethodChannel('cwms_mobile/vision_ocr')
            .invokeListMethod<dynamic>('recognizeText', {'path': image.path}) ??
        [];
    final lines = result.map(
        (row) => row is Map ? row['text']?.toString() ?? '' : row.toString());
    return LabelPhoto(bytes, labelUpcCandidates(lines));
  } finally {
    // The photo is only used for local review and is not uploaded or archived.
    try {
      await File(image.path).delete();
    } catch (_) {}
  }
}
