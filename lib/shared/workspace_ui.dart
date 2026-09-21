import 'package:flutter/material.dart';

const workspaceNavy = Color(0xFF142D4E);
const workspaceBlue = Color(0xFF2864DC);
const workspaceBackground = Color(0xFFF3F5F9);

bool workspaceIsChinese(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'zh';

IconData workspaceIcon(String name) {
  final value = name.toLowerCase();
  // Keep each operation visually distinct. These are semantic symbols rather
  // than one generic box recoloured for every menu item.
  if (value.contains('partial') && value.contains('move'))
    return Icons.compare_arrows_outlined;
  if (value.contains('putaway') || value.contains('put-away'))
    return Icons.drive_file_move_outlined;
  if (value.contains('lost') || value.contains('found'))
    return Icons.find_in_page_outlined;
  if (value.contains('sampling') || value.contains('sample'))
    return Icons.science_outlined;
  if (value.contains('audit')) return Icons.playlist_add_check_outlined;
  if (value.contains('cycle') && value.contains('count'))
    return Icons.fact_check_outlined;
  if (value.contains('barcode') || value.contains('scan'))
    return Icons.qr_code_scanner_outlined;
  if (value.contains('reverse') || value.contains('return'))
    return Icons.undo_rounded;
  if (value.contains('qc') || value.contains('quality'))
    return Icons.verified_outlined;
  if (value.contains('inbound') || value.contains('receiv'))
    return Icons.inbox_outlined;
  if (value.contains('outbound') || value.contains('pick'))
    return Icons.local_shipping_outlined;
  if (value.contains('inventory') || value.contains('count'))
    return Icons.inventory_2_outlined;
  if (value.contains('work') || value.contains('produc'))
    return Icons.precision_manufacturing_outlined;
  return Icons.dashboard_outlined;
}

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader(
      {super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        decoration: BoxDecoration(
          color: workspaceNavy,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.layers_outlined, color: Color(0xFF91B8FF), size: 17),
            SizedBox(width: 8),
            Expanded(
                child: Text('CLAYTECH ONE / WORKSPACE',
                    style: TextStyle(
                        color: Color(0xFFB7C9E4),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: Color(0xFFB7C9E4), fontSize: 12, height: 1.35)),
        ]),
      );
}

class WorkspaceTile extends StatelessWidget {
  const WorkspaceTile(
      {super.key,
      required this.title,
      required this.identity,
      required this.index,
      required this.onTap});
  final String title;
  final String identity;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [
      workspaceBlue,
      Color(0xFF168776),
      Color(0xFF91652D),
      Color(0xFF7855BD)
    ];
    final color = colors[index % colors.length];
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE4E9F1))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(workspaceIcon(identity), color: color, size: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: workspaceNavy,
                        height: 1.16)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class WorkspaceGrid extends StatelessWidget {
  const WorkspaceGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850
            ? 4
            : constraints.maxWidth >= 580
                ? 3
                : constraints.maxWidth >= 340
                    ? 2
                    : 1;
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final row = children.skip(start).take(columns).toList();
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < columns; index++) ...[
                  if (index > 0) const SizedBox(width: 14),
                  Expanded(
                    child: index < row.length ? row[index] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ));
          if (start + columns < children.length) {
            rows.add(const SizedBox(height: 14));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      });
}
