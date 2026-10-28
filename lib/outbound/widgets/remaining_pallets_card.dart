import 'package:flutter/material.dart';
import '../models/remaining_pallet_demand.dart';

class RemainingPalletsCard extends StatelessWidget {
  const RemainingPalletsCard(
      {super.key,
      required this.lines,
      this.updating = false,
      this.current = true,
      this.pendingConfirmation = false});
  final List<RemainingPalletDemand> lines;
  final bool updating;
  final bool current;
  final bool pendingConfirmation;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    String t(String en, String spanish) => es ? spanish : en;
    String pallets(int n) => es
        ? '$n ${n == 1 ? 'palé' : 'palés'}'
        : '$n ${n == 1 ? 'pallet' : 'pallets'}';
    String full(int n) => es
        ? '${pallets(n)} ${n == 1 ? 'completo' : 'completos'}'
        : '$n full ${n == 1 ? 'pallet' : 'pallets'}';
    final completeEstimate =
        lines.isNotEmpty && lines.every((l) => l.unitsPerPallet != null);
    final total = lines.fold<int>(0, (n, l) => n + (l.estimatedPallets ?? 0));
    const navy = Color(0xff163253);
    return Card(
      margin: const EdgeInsets.only(top: 20),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xffdfe6ef))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Remaining to pick', 'Pendiente de preparar'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: navy)),
          if (updating || !current) ...[
            const SizedBox(height: 8),
            Text(
                updating
                    ? t('Updating after confirmation…',
                        'Actualizando tras la confirmación…')
                    : pendingConfirmation
                        ? t('Finish the pending pick to refresh remaining quantities.',
                            'Complete la preparación pendiente para actualizar las cantidades.')
                        : t('Reload the order to see current remaining quantities.',
                            'Vuelva a cargar el pedido para ver las cantidades pendientes.'),
                style: const TextStyle(fontSize: 14)),
          ] else ...[
            if (completeEstimate) ...[
              const SizedBox(height: 8),
              Text(
                  t('Estimated: ${pallets(total)}',
                      'Estimado: ${pallets(total)}'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: navy)),
            ],
            for (final line in lines) ...[
              const Divider(height: 24),
              Text(line.itemName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: navy)),
              const SizedBox(height: 6),
              Text(
                  '${line.quantity} ${line.unit?.trim().isNotEmpty == true ? line.unit : t('units', 'unidades')} ${t('remaining', 'pendientes')}',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              if (line.unitsPerPallet == null)
                Text(
                    t('Pallet size not configured',
                        'Cantidad por palé sin configurar'),
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xff68778b)))
              else ...[
                Text(
                    [
                      if (line.fullPallets! > 0) full(line.fullPallets!),
                      if (line.looseQuantity! > 0)
                        '${line.looseQuantity} ${line.unit ?? t('units', 'unidades')}',
                    ].join(' + '),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                    '${t('Standard', 'Estándar')}: ${line.unitsPerPallet} ${line.unit ?? t('units', 'unidades')} / ${t('pallet', 'palé')}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xff68778b))),
              ],
            ],
            if (lines.isEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(t('No remaining quantity.',
                      'No queda cantidad pendiente.'))),
            if (lines.any((l) => l.unitsPerPallet != null)) ...[
              const SizedBox(height: 12),
              Text(
                  t('Estimated from standard pallet sizes. Actual pallets may vary.',
                      'Estimación según el tamaño estándar. Los palés reales pueden variar.'),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xff68778b))),
            ],
          ],
        ]),
      ),
    );
  }
}
