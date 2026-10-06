import 'package:flutter/material.dart';
import '../../shared/adaptive_layout.dart';
import '../../shared/workspace_ui.dart';

/// Keeps scanning controls reachable when a phone keyboard reduces the viewport.
class BarcodeReceivingLayout extends StatelessWidget {
  const BarcodeReceivingLayout({
    super.key,
    required this.scanTitle,
    required this.scanInstructions,
    required this.recentTitle,
    required this.barcodeInput,
    required this.actions,
    this.recentInventory,
  });

  final String scanTitle;
  final String scanInstructions;
  final String recentTitle;
  final Widget barcodeInput;
  final Widget actions;
  final Widget? recentInventory;

  @override
  Widget build(BuildContext context) => Material(
        color: workspaceBackground,
        textStyle: Theme.of(context).textTheme.bodyMedium!,
        child: SafeArea(
          top: false,
          child: TabletContent(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: AdaptiveSections(
                primary: _panel(
                  icon: Icons.qr_code_scanner_rounded,
                  title: scanTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(scanInstructions,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.blueGrey)),
                      const SizedBox(height: 18),
                      barcodeInput,
                      const SizedBox(height: 18),
                      actions,
                    ],
                  ),
                ),
                secondary: _panel(
                  icon: Icons.inventory_2_outlined,
                  title: recentTitle,
                  child: recentInventory ??
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.inventory_2_outlined,
                              size: 32, color: Color(0xFFBAC6D7)),
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _panel({
    required IconData icon,
    required String title,
    required Widget child,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E9F1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, size: 22, color: workspaceBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: workspaceNavy,
                        decoration: TextDecoration.none)),
              ),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}
