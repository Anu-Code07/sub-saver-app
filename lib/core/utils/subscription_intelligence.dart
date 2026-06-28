import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/dashboard/domain/entities/subscription_intelligence_entity.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

/// Intelligence layer — sits ABOVE autopay.
/// Tracks, splits, analyzes, and optimizes subscriptions across groups.
class SubscriptionIntelligenceEngine {
  const SubscriptionIntelligenceEngine();

  SubscriptionIntelligence analyze({
    required List<SubscriptionEntity> subscriptions,
    required List<GroupEntity> groups,
    required String currentUserId,
    List<ExpenseEntity> expenses = const [],
  }) {
    final active = subscriptions.where((s) => s.status == 'active').toList();
    final monthlyBurn = active.fold<double>(0, (total, s) => total + s.monthlyCost);
    final graph = _buildGraph(active, currentUserId);
    final totalSavings = graph.fold<double>(0, (t, n) => t + n.savingsFromSplit);
    final sharedCount = graph.where((n) => n.isShared).length;
    final duplicateCategories = _detectDuplicates(active);
    final insights = _generateInsights(active, duplicateCategories, monthlyBurn, totalSavings);
    final smartAlerts = _generateSmartAlerts(active, graph, expenses, groups, currentUserId);

    return SubscriptionIntelligence(
      monthlyBurn: monthlyBurn,
      yearlyBurn: monthlyBurn * 12,
      graph: graph,
      insights: insights,
      smartAlerts: smartAlerts,
      duplicateCategories: duplicateCategories,
      totalSavingsFromSplits: totalSavings * 12,
      sharedSubscriptionCount: sharedCount,
    );
  }

  List<SubscriptionGraphNode> _buildGraph(List<SubscriptionEntity> subs, String userId) {
    return subs.map((s) {
      final memberCount = s.members.isEmpty ? 1 : s.members.length;
      final isShared = memberCount > 1;
      final yourShare = isShared ? s.monthlyCost / memberCount : s.monthlyCost;
      final daysLeft = s.renewalDate.difference(DateTime.now()).inDays;

      return SubscriptionGraphNode(
        subscriptionId: s.id,
        name: s.name,
        provider: s.provider,
        monthlyCost: s.monthlyCost,
        memberCount: memberCount,
        yourShare: double.parse(yourShare.toStringAsFixed(2)),
        isShared: isShared,
        renewalDaysLeft: daysLeft,
        category: s.category,
      );
    }).toList();
  }

  Map<String, int> _detectDuplicates(List<SubscriptionEntity> subs) {
    final counts = <String, int>{};
    for (final s in subs) {
      counts[s.category.label] = (counts[s.category.label] ?? 0) + 1;
    }
    return Map.fromEntries(counts.entries.where((e) => e.value >= 2));
  }

  List<SmartInsight> _generateInsights(
    List<SubscriptionEntity> subs,
    Map<String, int> duplicates,
    double monthlyBurn,
    double monthlySavings,
  ) {
    final insights = <SmartInsight>[];

    if (subs.isEmpty) {
      insights.add(const SmartInsight(
        type: InsightType.general,
        title: 'Discover your subscriptions',
        message: 'Most people don\'t know what they pay for. Add subscriptions to build your graph.',
      ));
      return insights;
    }

    insights.add(SmartInsight(
      type: InsightType.highBurn,
      title: 'Monthly subscription burn',
      message: 'You\'re spending ₹${monthlyBurn.toStringAsFixed(0)}/month across ${subs.length} services. Autopay only executes — SubSavr shows you the full picture.',
      severity: monthlyBurn > 3000 ? InsightSeverity.warning : InsightSeverity.info,
    ));

    if (duplicates.containsKey('OTT') && duplicates['OTT']! >= 3) {
      final names = subs
          .where((s) => s.category == SubscriptionCategory.ott)
          .map((s) => s.name)
          .take(3)
          .join(' + ');
      insights.add(SmartInsight(
        type: InsightType.duplicateServices,
        title: 'Duplicate streaming services',
        message: 'You have $names. Consider downgrading one plan to save ₹120–300/month.',
        severity: InsightSeverity.warning,
        actionLabel: 'Review OTT',
      ));
    }

    if (duplicates.containsKey('AI Tools') && duplicates['AI Tools']! >= 2) {
      insights.add(const SmartInsight(
        type: InsightType.duplicateServices,
        title: 'Multiple AI subscriptions',
        message: 'ChatGPT + Claude + Copilot? Pick one primary tool and cancel the rest.',
        severity: InsightSeverity.warning,
      ));
    }

    if (monthlySavings > 0) {
      insights.add(SmartInsight(
        type: InsightType.savingsOpportunity,
        title: 'Savings from splitting',
        message: 'You\'re saving ~₹${monthlySavings.toStringAsFixed(0)}/month by sharing subscriptions with others.',
        severity: InsightSeverity.success,
      ));
    }

    final soloHighCost = subs.where((s) => s.members.length <= 1 && s.monthlyCost > 500);
    for (final s in soloHighCost.take(2)) {
      insights.add(SmartInsight(
        type: InsightType.savingsOpportunity,
        title: 'Family plan opportunity',
        message: '${s.name} at ₹${s.cost.toStringAsFixed(0)} — a family plan with friends could cut your share by 50%+.',
        actionLabel: 'Create group',
      ));
    }

    return insights;
  }

  List<SmartInsight> _generateSmartAlerts(
    List<SubscriptionEntity> subs,
    List<SubscriptionGraphNode> graph,
    List<ExpenseEntity> expenses,
    List<GroupEntity> groups,
    String currentUserId,
  ) {
    final alerts = <SmartInsight>[];

    for (final node in graph) {
      if (node.renewalDaysLeft >= 0 && node.renewalDaysLeft <= 7) {
        final pendingMembers = node.memberCount > 1 ? node.memberCount - 1 : 0;
        alerts.add(SmartInsight(
          type: InsightType.renewalAlert,
          title: '${node.name} renews ${node.renewalDaysLeft == 0 ? 'today' : 'in ${node.renewalDaysLeft} days'}',
          message: pendingMembers > 0
              ? 'Your share is ₹${node.yourShare.toStringAsFixed(0)}. $pendingMembers member(s) may still be pending.'
              : 'Your share is ₹${node.yourShare.toStringAsFixed(0)}.',
          severity: node.renewalDaysLeft <= 1 ? InsightSeverity.critical : InsightSeverity.warning,
        ));
      }

      if (node.isShared && node.memberCount > 2) {
        final usagePct = (100 / node.memberCount).round();
        if (usagePct < 50) {
          alerts.add(SmartInsight(
            type: InsightType.unusedShare,
            title: 'Shared but under-split',
            message: 'You pay for ${node.name} but only use ~$usagePct% of the cost. Consider renegotiating splits.',
            severity: InsightSeverity.info,
          ));
        }
      }
    }

    for (final expense in expenses) {
      final pending = expense.splits.where((s) => s.status == PaymentStatus.pending && s.uid != currentUserId);
      for (final split in pending) {
        final name = split.name ?? 'A member';
        alerts.add(SmartInsight(
          type: InsightType.memberPending,
          title: '$name hasn\'t paid yet',
          message: '${expense.subscriptionName ?? 'Subscription'} — ₹${split.amount.toStringAsFixed(0)} pending.',
          severity: InsightSeverity.warning,
          actionLabel: 'Send reminder',
        ));
      }
    }

    if (alerts.isEmpty && subs.isNotEmpty) {
      alerts.add(const SmartInsight(
        type: InsightType.general,
        title: 'All caught up',
        message: 'No pending renewals or member payments in the next 7 days.',
        severity: InsightSeverity.success,
      ));
    }

    return alerts;
  }
}
