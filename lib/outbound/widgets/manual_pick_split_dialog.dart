import '../../shared/scanning/scan_feedback.dart';
import 'package:cwms_mobile/i18n/spanish_ui.dart';
import 'package:flutter/material.dart';

class ManualPickSplitDialog extends StatefulWidget {
  const ManualPickSplitDialog(
      {super.key,
      required this.sourceLpn,
      required this.sourceQuantity,
      required this.pickableQuantity});
  final String sourceLpn;
  final int sourceQuantity, pickableQuantity;
  @override
  State<ManualPickSplitDialog> createState() => _ManualPickSplitDialogState();
}

class _ManualPickSplitDialogState extends State<ManualPickSplitDialog> {
  final form = GlobalKey<FormState>();
  late final quantity =
      TextEditingController(text: widget.pickableQuantity.toString());
  final newLpn = TextEditingController();
  bool keepOriginal = false;
  int get count => int.tryParse(quantity.text) ?? 0;
  bool get partial => count < widget.sourceQuantity;
  bool get es => Localizations.localeOf(context).languageCode == 'es';
  String t(String en, String spanish) => es ? spanish : en;
  @override
  void dispose() {
    quantity.dispose();
    newLpn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(t('Confirm pallet pick', 'Confirmar preparación del palé')),
        content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(uiTemplate(
                              context, "LPN: {0}", [widget.sourceLpn])),
                          Text(
                              '${t('Pallet quantity', 'Cantidad del palé')}: ${widget.sourceQuantity}'),
                          Text(
                              '${t('Maximum to pick', 'Máximo para preparar')}: ${widget.pickableQuantity}'),
                          TextFormField(
                              controller: quantity,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: t('Quantity to pick',
                                      'Cantidad para preparar')),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return n == null ||
                                        n <= 0 ||
                                        n > widget.pickableQuantity
                                    ? t('Enter a quantity within the remaining demand',
                                        'Introduzca una cantidad dentro de la demanda pendiente')
                                    : null;
                              }),
                          if (partial) ...[
                            RadioListTile<bool>(
                                value: false,
                                groupValue: keepOriginal,
                                onChanged: (v) =>
                                    setState(() => keepOriginal = v!),
                                title: Text(t(
                                    'Original LPN stays with remaining stock',
                                    'El LPN original queda con el inventario restante'))),
                            RadioListTile<bool>(
                                value: true,
                                groupValue: keepOriginal,
                                onChanged: (v) =>
                                    setState(() => keepOriginal = v!),
                                title: Text(t(
                                    'Original LPN goes with this order',
                                    'El LPN original acompaña a este pedido'))),
                            Text(keepOriginal
                                ? t('Take $count units using ${widget.sourceLpn}. Attach the new label to the remaining ${widget.sourceQuantity - count} units.',
                                    'Retire $count unidades con ${widget.sourceLpn}. Coloque la etiqueta nueva en las ${widget.sourceQuantity - count} unidades restantes.')
                                : t('Take $count units and attach the new label. Leave ${widget.sourceQuantity - count} units with ${widget.sourceLpn}.',
                                    'Retire $count unidades y coloque la etiqueta nueva. Deje ${widget.sourceQuantity - count} unidades con ${widget.sourceLpn}.')),
                            TextFormField(
                                controller: newLpn,
                                autofocus: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      tooltip:
                                          t('Scan label', 'Escanear etiqueta'),
                                      icon:
                                          const Icon(Icons.camera_alt_outlined),
                                      onPressed: () async {
                                        final scanned =
                                            await Navigator.of(context)
                                                .pushNamed('qr_code_view');
                                        if (mounted &&
                                            scanned is String &&
                                            scanned.trim().isNotEmpty)
                                          newLpn.text = scanned.trim();
                                      },
                                    ),
                                    labelText: uiText(
                                        context,
                                        keepOriginal
                                            ? t('New LPN for remaining stock',
                                                'LPN nuevo para inventario restante')
                                            : t('New LPN for picked units',
                                                'LPN nuevo para unidades preparadas'))),
                                validator: (v) {
                                  final x = (v ?? '').trim();
                                  return x == widget.sourceLpn ||
                                          x.startsWith('DE') ||
                                          !RegExp(r'^[A-Z][A-Z0-9]{7,11}$')
                                              .hasMatch(x)
                                      ? t('Scan a different ordinary preprinted LPN',
                                          'Escanee otro LPN normal preimpreso')
                                      : null;
                                }),
                            Text(t(
                                'Remaining stock stays at its original location.',
                                'El inventario restante permanece en su ubicación original.')),
                          ] else
                            Text(t(
                                'Pick the full pallet using its original LPN.',
                                'Prepare el palé completo con su LPN original.')),
                        ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Cancel', 'Cancelar'))),
          FilledButton(
              onPressed: () {
                if (form.currentState!.validate())
                  Navigator.pop(context, {
                    'quantity': count,
                    'newLpn': partial ? newLpn.text.trim() : '',
                    'keepOriginal': keepOriginal
                  });
                else {
                  ScanFeedback.run(() async {
                    ScanFeedback.reportError('Invalid LPN or picking quantity');
                  });
                }
              },
              child: Text(t('Confirm pick', 'Confirmar preparación')))
        ],
      );
}
