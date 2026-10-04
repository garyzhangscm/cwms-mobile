import 'package:flutter/material.dart';

/// Uses the available window width, including iPad split-screen windows.
class TabletContent extends StatelessWidget {
  const TabletContent({super.key, required this.child, this.maxWidth = 1180});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );
}

/// Stacks on phones and narrow windows; shows two full-size panels on tablets.
class AdaptiveSections extends StatelessWidget {
  const AdaptiveSections(
      {super.key,
      required this.primary,
      required this.secondary,
      this.header,
      this.footer});
  final Widget primary;
  final Widget secondary;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[header!, const SizedBox(height: 16)],
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: primary),
                    const SizedBox(width: 24),
                    Expanded(child: secondary),
                  ])
                else ...[primary, const SizedBox(height: 12), secondary],
                if (footer != null) ...[
                  const SizedBox(height: 16),
                  Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: wide ? 550 : double.infinity),
                          child: SizedBox(
                              width: double.infinity, child: footer!))),
                ],
              ]);
        },
      );
}
