import 'package:flutter/material.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/features/dashboard/domain/entities/subscription_intelligence_entity.dart';

class IntelligenceBanner extends StatelessWidget {
  const IntelligenceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.tertiaryAccent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hub_outlined, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Intelligence layer — not autopay. Track, split & optimize.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class SmartAlertCard extends StatelessWidget {
  const SmartAlertCard({super.key, required this.insight});

  final SmartInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.severity) {
      InsightSeverity.critical => AppColors.overdueRed,
      InsightSeverity.warning => AppColors.pendingOrange,
      InsightSeverity.success => AppColors.paidGreen,
      InsightSeverity.info => AppColors.primaryContainer,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(insight.type), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(insight.message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(InsightType type) => switch (type) {
        InsightType.renewalAlert => Icons.event_repeat,
        InsightType.memberPending => Icons.person_off_outlined,
        InsightType.duplicateServices => Icons.copy_all_outlined,
        InsightType.unusedShare => Icons.pie_chart_outline,
        InsightType.savingsOpportunity => Icons.savings_outlined,
        InsightType.highBurn => Icons.local_fire_department_outlined,
        InsightType.general => Icons.lightbulb_outline,
      };
}

class SubscriptionGraphCard extends StatelessWidget {
  const SubscriptionGraphCard({super.key, required this.node});

  final SubscriptionGraphNode node;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(node.provider.isNotEmpty ? node.provider[0] : '?', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      node.isShared
                          ? '₹${node.monthlyCost.toStringAsFixed(0)} → ${node.memberCount} people · You pay ₹${node.yourShare.toStringAsFixed(0)}'
                          : '₹${node.monthlyCost.toStringAsFixed(0)} · Solo',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (node.isShared)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Save ${CurrencyFormatter.format(node.savingsFromSplit)}/mo',
                    style: const TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (node.isShared) ...[
            const SizedBox(height: 10),
            _GraphBar(sharedPct: (100 / node.memberCount).round()),
          ],
        ],
      ),
    );
  }
}

class _GraphBar extends StatelessWidget {
  const _GraphBar({required this.sharedPct});

  final int sharedPct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('You', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sharedPct / 100,
              minHeight: 6,
              backgroundColor: AppColors.graphiteLight,
              color: AppColors.accentGreen,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$sharedPct%', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}
