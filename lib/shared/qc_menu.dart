import '../workorder/routes/line_clearance_test.dart';
import '../auth/models/menu.dart';
import '../auth/models/menu_sub_group.dart';
import '../workorder/models/defective_production.dart';
import '../workorder/models/rfid_check.dart';

const qcMenuIdentity = 'qc_workspace';
const qcMenuOrder = [
  'inbound_qc',
  'work_order_qc',
  'work_order_qc_sampling',
  if (lineClearanceTestEnabled) 'line_clearance_test',
  'work_order_rfid_check',
  'work_order_rfid_pallet',
  'inventory_qc',
  'item_sampling',
  'qc_inspection',
  'work_order_defective'
];

/// Shortcuts only: derive from the same authorized menus as existing entries.
List<Menu> qcMenuItems(
    List<MenuSubGroup> groups, bool Function(String?) registered) {
  final authorized =
      groups.expand((g) => g.menus).where((m) => registered(m.link)).toList();
  final expanded = withRfidCheckMenu(withDefectiveProductionMenu(authorized));
  if (lineClearanceTestEnabled && authorized.any((m) => ['work_order_qc_sampling','work_order_qc','work_order_produce','qc_inspection'].contains(m.link))) {
    expanded.add(Menu()..name='Line Clearance TEST'..text='Line Clearance TEST'..link='line_clearance_test');
  }
  final byRoute = <String, Menu>{};
  for (final menu in expanded) {
    if (qcMenuOrder.contains(menu.link) && registered(menu.link)) {
      byRoute.putIfAbsent(menu.link!, () => menu);
    }
  }
  return qcMenuOrder
      .where(byRoute.containsKey)
      .map((route) => byRoute[route]!)
      .toList();
}
