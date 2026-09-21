

import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:flutter/material.dart';

class ReceiptListItem extends StatefulWidget {
  ReceiptListItem({required this.index, required this.receipt,
          this.highlighted = false,
          required this.onToggleHightlighted}
       ) : super(key: ValueKey(receipt.number));

  final ValueChanged<bool> onToggleHightlighted;

  bool highlighted;

  final int index;
  final Receipt receipt;



  @override
  _ReceiptListItemState createState() => _ReceiptListItemState();


}

class _ReceiptListItemState extends State<ReceiptListItem> {

  void _onToggleHightlighted() {
    setState(() {
      widget.highlighted = !widget.highlighted;
    });
    widget.onToggleHightlighted(widget.highlighted);
  }

  @override
  Widget build(BuildContext context) {
    final zh = workspaceIsChinese(context);
    final expected = widget.receipt.totalExpectedQuantity ?? 0;
    final received = widget.receipt.totalReceivedQuantity ?? 0;
    return Material(
      color: widget.highlighted ? const Color(0xFFEAF3FF) : Colors.white,
      child: InkWell(
        onTap: _onToggleHightlighted,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 15, 18, 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receipt.number ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF142D4E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zh
                          ? '已收 $received  ·  应收 $expected'
                          : 'Received $received  ·  Expected $expected',
                      style: const TextStyle(
                        color: Color(0xFF748297),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF9AA8B8), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
