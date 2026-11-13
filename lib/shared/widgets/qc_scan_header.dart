import 'package:flutter/material.dart';

class QcScanHeader extends StatelessWidget {
  const QcScanHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF172F50),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: Color(0xFF9FC5FF), size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                Text(title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Color(0xB8FFFFFF), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
