import 'package:flutter/material.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = switch (status) {
      PaymentStatus.paid => (AppColors.tertiary, AppColors.onTertiaryContainer, status.label),
      PaymentStatus.pending => (AppColors.secondary, const Color(0xFFFFE8E7), status.label),
      PaymentStatus.overdue => (AppColors.error, AppColors.errorContainer, status.label),
      PaymentStatus.partiallyPaid => (AppColors.secondary, const Color(0xFFFFE8E7), status.label),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
