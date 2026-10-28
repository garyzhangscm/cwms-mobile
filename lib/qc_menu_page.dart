import 'shared/scanning/scan_app_bar.dart';
import 'shared/rfid_capability.dart';
import 'package:flutter/material.dart';
import 'auth/models/menu.dart';
import 'shared/workspace_ui.dart';
import 'shared/menu_navigation.dart';

class QcMenuPage extends StatelessWidget {
  const QcMenuPage({super.key, required this.menus});
  final List<Menu> menus;
  String text(BuildContext context, String en, String es, String zh) {
    final language = Localizations.localeOf(context).languageCode;
    return language == 'es'
        ? es
        : language == 'zh'
            ? zh
            : en;
  }

  String label(BuildContext c, Menu m) => switch (m.link) {
        'line_clearance_test' => text(c, 'Line Clearance · TEST', 'Despeje de línea · PRUEBA', '清线检查 · 测试'),
        'inbound_qc' => text(c, 'Inbound QC', 'Control de recepción', '来料质检'),
        'work_order_qc' =>
          text(c, 'Work Order QC', 'Control de orden de trabajo', '工单质检'),
        'work_order_qc_sampling' =>
          text(c, 'QC Sampling', 'Muestreo de calidad', '质检抽样'),
        'work_order_rfid_check' => text(c, 'RFID Label Check',
            'Verificación de etiqueta RFID', 'RFID 标签核对'),
        'work_order_rfid_pallet' =>
          text(c, 'RFID Pallet Scan', 'Escaneo RFID de palé', 'RFID 整托扫描'),
        'inventory_qc' =>
          text(c, 'Inventory QC', 'Control de inventario', '库存质检'),
        'item_sampling' =>
          text(c, 'Item Sampling', 'Muestreo de productos', '产品抽样'),
        'qc_inspection' =>
          text(c, 'QC Inspection', 'Inspección de calidad', '质量检查'),
        'work_order_defective' =>
          text(c, 'Defective', 'Producción defectuosa', '废品报产'),
        _ => m.text ?? m.name ?? '',
      };
  @override
  Widget build(BuildContext context) => RfidMenuGate(builder: _buildMenu);

  Widget _buildMenu(BuildContext context) {
    final visible =
        menus.where((m) => hasRegisteredMenuRoute(context, m.link)).toList();
    final checks =
        visible.where((m) => m.link != 'work_order_defective').toList();
    final reports =
        visible.where((m) => m.link == 'work_order_defective').toList();
    Widget tiles(List<Menu> items) => WorkspaceGrid(children: [
          for (var i = 0; i < items.length; i++)
            WorkspaceTile(
                title: label(context, items[i]),
                identity: '${items[i].name} ${items[i].link}',
                index: i,
                onTap: () => Navigator.of(context).pushNamed(items[i].link!))
        ]);
    Widget heading(String value) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: workspaceNavy)));
    return Scaffold(
        backgroundColor: workspaceBackground,
        appBar: ScanAppBar(
            title: Text(text(context, 'QC', 'Control de calidad', '质量管理')),
            backgroundColor: workspaceBackground,
            foregroundColor: workspaceNavy),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WorkspaceHeader(
                                  title: text(context, 'Quality Control',
                                      'Control de calidad', '质量管理'),
                                  subtitle: text(
                                      context,
                                      'Choose a quality check or report defective output.',
                                      'Seleccione un control de calidad o registre producción defectuosa.',
                                      '选择检查功能或登记废品报产。')),
                              const RfidHardwareNotice(),
                            if (checks.isNotEmpty) ...[
                                heading(text(context, 'Quality checks',
                                    'Controles de calidad', '质量检查')),
                                tiles(checks)
                              ],
                              if (reports.isNotEmpty) ...[
                                heading(text(context, 'Defective reporting',
                                    'Registro de defectuosos', '废品报产')),
                                Text(text(
                                    context,
                                    'Records defective output and updates inventory and work order quantities.',
                                    'Registra producción defectuosa y actualiza el inventario y las cantidades de la orden.',
                                    '登记废品产量，并更新库存和工单产量。')),
                                const SizedBox(height: 16),
                                tiles(reports)
                              ],
                            ]))))));
  }
}
