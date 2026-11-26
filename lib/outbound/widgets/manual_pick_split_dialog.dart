import '../../shared/scanning/scan_feedback.dart';
import '../services/preprinted_manual_pick.dart';
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

class GuidedManualPickSplitDialog extends StatefulWidget {
  const GuidedManualPickSplitDialog({
    super.key,
    required this.sourceLpn,
    required this.sourceQuantity,
    required this.pickableQuantity,
  });

  final String sourceLpn;
  final int sourceQuantity;
  final int pickableQuantity;

  @override
  State<GuidedManualPickSplitDialog> createState() =>
      _GuidedManualPickSplitDialogState();
}

class _GuidedManualPickSplitDialogState
    extends State<GuidedManualPickSplitDialog> {
  late final _quantity =
      TextEditingController(text: '${widget.pickableQuantity}');
  final _label = TextEditingController();
  final _focus = FocusNode();
  int _step = 0;
  String? _pickedLabel;
  String? _remainderLabel;
  String? _error;
  bool _checking = false;

  int get _count => int.tryParse(_quantity.text) ?? 0;

  @override
  void dispose() {
    _quantity.dispose();
    _label.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
      _label.text = (step == 1 ? _pickedLabel : _remainderLabel) ?? '';
    });
    if (step == 1 || step == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == step) _focus.requestFocus();
      });
    }
  }

  void _rejectLabel(String message) {
    setState(() {
      _error = message;
      _label.clear();
    });
    _focus.requestFocus();
  }

  Future<void> _acceptLabel(String input) async {
    if (_checking) return;
    final label = input.trim().toUpperCase();
    if (!RegExp(r'^[A-Z][A-Z0-9]{7,11}$').hasMatch(label) ||
        label.startsWith('DE') ||
        label == widget.sourceLpn.toUpperCase() ||
        label == (_step == 1 ? _remainderLabel : _pickedLabel)) {
      _rejectLabel('Scan a different preprinted LPN.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final error = await PreprintedManualPickService.validateSplitLabel(label)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (error != null) {
        _rejectLabel(error);
        return;
      }
      if (_step == 1) {
        _pickedLabel = label;
      } else {
        _remainderLabel = label;
      }
      _goTo(_step + 1);
    } catch (_) {
      if (mounted) _rejectLabel('Could not verify this LPN. Scan again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.sourceQuantity - _count;
    final scanning = _step == 1 || _step == 2;
    return AlertDialog(
      title: Text(switch (_step) {
        0 => 'Split pallet',
        1 => '1 of 2 · Picked stock',
        2 => '2 of 2 · Remaining stock',
        _ => 'Review pallet split',
      }),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.sourceLpn} · ${widget.sourceQuantity} units'),
              const SizedBox(height: 12),
              if (_step == 0)
                TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity to pick',
                    helperText: 'Maximum ${widget.pickableQuantity}',
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              if (scanning) ...[
                Text(_step == 1
                    ? 'Separate $_count units and scan their new LPN.'
                    : 'Scan the new LPN for the $remaining units left on the original pallet.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _label,
                  focusNode: _focus,
                  readOnly: _checking,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {},
                  onSubmitted: _acceptLabel,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    labelText:
                        _step == 1 ? 'New picked LPN' : 'New remainder LPN',
                    errorText: _error,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Scan label',
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: _checking
                          ? null
                          : () async {
                              final scanned = await Navigator.of(context)
                                  .pushNamed('qr_code_view');
                              if (mounted &&
                                  scanned is String &&
                                  scanned.trim().isNotEmpty) {
                                _label.text = scanned;
                                await _acceptLabel(scanned);
                              }
                            },
                    ),
                  ),
                ),
                if (_checking) const LinearProgressIndicator(),
              ],
              if (_step == 3) ...[
                Text('Pick $_count units · $_pickedLabel'),
                const SizedBox(height: 8),
                Text(
                    'Keep $remaining units at the original location · $_remainderLabel'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_step == 0)
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'))
        else
          TextButton(
              onPressed: _checking ? null : () => _goTo(_step - 1),
              child: const Text('Back')),
        FilledButton(
          onPressed: _checking
              ? null
              : () {
                  if (_step == 0) {
                    if (_count <= 0 || _count > widget.pickableQuantity) {
                      setState(() => _error =
                          'Enter a quantity within the remaining demand.');
                      return;
                    }
                    _goTo(1);
                  } else if (scanning) {
                    _acceptLabel(_label.text);
                  } else {
                    Navigator.pop(context, {
                      'quantity': _count,
                      'newLpn': _pickedLabel!,
                      'remainderLpn': _remainderLabel!,
                      'keepOriginal': false,
                    });
                  }
                },
          child: Text(_step == 3 ? 'Confirm Pick' : 'Next'),
        ),
      ],
    );
  }
}
