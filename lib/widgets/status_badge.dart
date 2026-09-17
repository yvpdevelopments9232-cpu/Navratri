import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'valid':
      case 'in stock':
        bg = const Color(0xFFE6F4EA);
        text = const Color(0xFF137333);
        break;
      case 'pending':
      case 'partial':
      case 'scheduled':
        bg = const Color(0xFFFEF7E0);
        text = const Color(0xFFB06000);
        break;
      case 'upcoming':
        bg = const Color(0xFFE8F0FE);
        text = const Color(0xFF1967D2);
        break;
      case 'inactive':
      case 'cancelled':
      case 'expired':
      case 'out of stock':
        bg = const Color(0xFFFCE8E6);
        text = const Color(0xFFC5221F);
        break;
      default:
        bg = const Color(0xFFF1F3F4);
        text = const Color(0xFF3C4043);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withAlpha(50)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
