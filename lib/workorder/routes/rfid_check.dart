import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rfid_check.dart';
import '../services/rfid_label_camera.dart';

class RfidCheckPage extends StatefulWidget {
  const RfidCheckPage({super.key, this.captureLabel});
  final Future<LabelPhoto?> Function()? captureLabel;
  @override
  State<RfidCheckPage> createState() => _RfidCheckPageState();
}

class _RfidCheckPageState extends State<RfidCheckPage>
    with WidgetsBindingObserver {
  static const channel = MethodChannel('cwms_mobile/rfid');
  final upc = TextEditingController();
  final upcFocus = FocusNode();
  void updateTrigger() {
    var valid = false;
    try {
      normalizeGtin(upc.text);
      valid = true;
    } on FormatException {}
    channel
        .invokeMethod<void>('arm', valid && !upcFocus.hasFocus && !ocrBusy)
        .catchError((Object _) {});
  }

  bool busy = false, ocrBusy = false;
  String? error;
  RfidComparison? comparison;
  List<String> tags = [];
  int generation = 0;
  String tr(String en, String es) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;
  @override
  void initState() {
    super.initState();
    upcFocus.addListener(updateTrigger);
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method == 'trigger' && mounted) await scan();
    });
    channel.invokeMethod<void>('activate').catchError((Object _) {});
  }

  void cancelScan() {
    generation++;
    channel.invokeMethod<void>('cancel').catchError((Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      channel.invokeMethod<void>('activate').catchError((Object _) {});
      updateTrigger();
    } else {
      cancelScan();
      if (mounted)
        setState(() {
          busy = false;
          comparison = null;
          tags = [];
        });
    }
  }

  @override
  void dispose() {
    cancelScan();
    channel.invokeMethod<void>('deactivate').catchError((Object _) {});
    channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    upcFocus.removeListener(updateTrigger);
    upcFocus.dispose();
    upc.dispose();
    super.dispose();
  }

  Future<void> photograph() async {
    if (busy || ocrBusy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      ocrBusy = true;
      comparison = null;
      tags = [];
      error = null;
      upc.clear();
    });
    updateTrigger();
    try {
      final photo = await (widget.captureLabel ?? captureRfidLabel)();
      if (!mounted || photo == null) return;
      final edit = TextEditingController(
          text: photo.candidates.length == 1 ? photo.candidates.single : '');
      String? validation;
      final reviewRoute = DialogRoute<String>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
              builder: (context, change) => AlertDialog(
                    title: Text(
                        tr('Confirm printed UPC', 'Confirmar UPC impreso')),
                    content: SizedBox(
                        width: 420,
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Image.memory(photo.bytes,
                                  height: 200, fit: BoxFit.contain),
                              Text(tr(
                                  'Check the digits against the photo before continuing.',
                                  'Compruebe los dígitos con la foto antes de continuar.')),
                              if (photo.candidates.isEmpty)
                                Text(tr(
                                    'No valid UPC detected. Enter the printed digits or retake the photo.',
                                    'No se detectó un UPC válido. Introduzca los dígitos impresos o repita la foto.')),
                              if (photo.candidates.length > 1) ...[
                                Text(tr(
                                    'Multiple codes found. Select the printed product UPC.',
                                    'Se encontraron varios códigos. Seleccione el UPC del producto.')),
                                for (final candidate in photo.candidates)
                                  TextButton(
                                      onPressed: () => change(() {
                                            edit.text = candidate;
                                            validation = null;
                                          }),
                                      child: Text(candidate)),
                              ],
                              TextField(
                                  controller: edit,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: 'UPC / GTIN',
                                      errorText: validation),
                                  onChanged: (_) => change(() {
                                        validation = null;
                                      })),
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                              tr('Cancel / Retake', 'Cancelar / Repetir'))),
                      FilledButton(
                          onPressed: () {
                            try {
                              normalizeGtin(edit.text);
                              Navigator.pop(dialogContext, edit.text.trim());
                            } on FormatException {
                              change(() {
                                validation = tr(
                                    'Check the digits and check digit.',
                                    'Revise los dígitos y el dígito de control.');
                              });
                            }
                          },
                          child: Text(tr('Use this UPC', 'Usar este UPC'))),
                    ],
                  )));
      final selected = await Navigator.of(context).push(reviewRoute);
      await reviewRoute.completed;
      edit.dispose();
      if (!mounted || selected == null) return;
      setState(() {
        upc.text = selected;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          error = tr(
              'Unable to read the photo. Try again or enter the UPC manually.',
              'No se pudo leer la foto. Inténtelo de nuevo o introduzca el UPC manualmente.');
        });
    } finally {
      if (mounted) {
        setState(() {
          ocrBusy = false;
        });
        updateTrigger();
      }
    }
  }

  Future<void> scan() async {
    if (busy || ocrBusy) return;
    try {
      normalizeGtin(upc.text);
    } on FormatException {
      setState(() {
        comparison = null;
        error = tr('Enter a valid UPC (12 digits), EAN (13) or GTIN (14).',
            'Introduzca un UPC válido (12 dígitos), EAN (13) o GTIN (14).');
      });
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      setState(() {
        comparison = null;
        error = tr(
            'RFID reading requires a supported Chainway Android handheld.',
            'La lectura RFID requiere un terminal Android Chainway compatible.');
      });
      return;
    }
    final expected = upc.text;
    final token = ++generation;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      comparison = null;
      tags = [];
    });
    try {
      final found = await channel.invokeListMethod<String>('scan') ?? [];
      if (!mounted || token != generation) return;
      setState(() {
        tags = found;
        comparison = compareRfid(expected, found);
      });
    } catch (_) {
      if (!mounted || token != generation) return;
      setState(() {
        error = tr(
            'RFID reader unavailable. Close the UHF demo app and use a compatible Chainway device with the RFID APK installed.',
            'Lector RFID no disponible. Cierre la aplicación de demostración UHF y use un equipo Chainway compatible con el APK RFID instalado.');
      });
    } finally {
      if (mounted && token == generation)
        setState(() {
          busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final outcome = comparison?.outcome;
    final label = switch (outcome) {
      RfidOutcome.pass => tr('PASS', 'CORRECTO'),
      RfidOutcome.mismatch =>
        tr('FAIL — UPC does not match', 'INCORRECTO — El UPC no coincide'),
      RfidOutcome.noTag => tr('No tag detected. Try again.',
          'No se detectó ninguna etiqueta. Inténtelo de nuevo.'),
      RfidOutcome.multipleTags => tr(
          'Multiple tags detected. Isolate one product.',
          'Se detectaron varias etiquetas. Separe un solo producto.'),
      RfidOutcome.unsupported => tr(
          'Unsupported RFID encoding. Expected SGTIN-96.',
          'Codificación RFID no compatible. Se requiere SGTIN-96.'),
      null => '',
    };
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('RFID Label Check', 'Verificación de etiqueta RFID'))),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(tr(
                        'Photograph the printed UPC and confirm the digits, or enter it manually. Then isolate one product and tap Read RFID to compare with the chip.',
                        'Fotografíe el UPC impreso y confirme los dígitos, o introdúzcalo manualmente. Después separe un producto y pulse Leer RFID para compararlo con el chip.')),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                        onPressed: busy || ocrBusy ? null : photograph,
                        icon: const Icon(Icons.photo_camera),
                        label: Text(ocrBusy
                            ? tr('Reading label…', 'Leyendo etiqueta…')
                            : tr('Take Photo', 'Tomar foto'))),
                    const SizedBox(height: 12),
                    TextField(
                        controller: upc,
                        focusNode: upcFocus,
                        enabled: !busy && !ocrBusy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'UPC / GTIN',
                            border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {
                              comparison = null;
                              tags = [];
                              error = null;
                            }),
                        onSubmitted: (_) => scan()),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        onPressed: busy || ocrBusy ? null : scan,
                        icon: const Icon(Icons.sensors),
                        label: Text(busy
                            ? tr('Reading…', 'Leyendo…')
                            : tr('Read RFID', 'Leer RFID'))),
                    if (busy) const LinearProgressIndicator(),
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(error!,
                              style: const TextStyle(color: Colors.red))),
                    if (comparison != null)
                      Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: outcome == RfidOutcome.pass
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16)),
                          child: Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: outcome == RfidOutcome.pass
                                      ? Colors.green.shade800
                                      : outcome == RfidOutcome.mismatch
                                          ? Colors.red.shade800
                                          : Colors.brown))),
                    if (comparison?.gtin != null)
                      SelectableText('GTIN: ${comparison!.gtin}'),
                    for (final tag in tags) SelectableText('EPC: $tag'),
                    const SizedBox(height: 20),
                    Text(tr(
                        'Read-only check. No inventory or production is changed.',
                        'Solo verificación. No modifica inventario ni producción.')),
                  ]))),
    );
  }
}
