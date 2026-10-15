import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.pending() {
    return const StatusBadge(
      label: 'PENDING',
      bgColor: AppColors.amberLight,
      textColor: AppColors.amberDark,
      icon: Icons.access_time_rounded,
    );
  }

  factory StatusBadge.completed() {
    return const StatusBadge(
      label: 'COMPLETED',
      bgColor: AppColors.emeraldLight,
      textColor: AppColors.emeraldDark,
      icon: Icons.check_circle_rounded,
    );
  }

  factory StatusBadge.cancelled() {
    return const StatusBadge(
      label: 'CANCELLED',
      bgColor: AppColors.roseLight,
      textColor: AppColors.roseRed,
      icon: Icons.cancel_rounded,
    );
  }

  factory StatusBadge.lowStock(int count) {
    return StatusBadge(
      label: 'Low: $count left',
      bgColor: const Color(0xFFFFEDD5),
      textColor: const Color(0xFFC2410C),
      icon: Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class CounterPill extends StatelessWidget {
  final int count;
  final bool isSelected;

  const CounterPill({
    super.key,
    required this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.3)
            : AppColors.textMuted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
