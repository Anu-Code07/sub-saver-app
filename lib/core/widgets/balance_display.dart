import 'package:flutter/material.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({
    super.key,
    required this.amount,
    this.label,
    this.currencySymbol = AppConstants.currencySymbol,
    this.fontSize = 36,
  });

  final double amount;
  final String? label;
  final String currencySymbol;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          '$currencySymbol${_formatAmount(amount)}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}
