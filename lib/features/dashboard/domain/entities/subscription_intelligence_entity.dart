import 'package:equatable/equatable.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';

/// A node in the user's subscription graph: who pays, who shares, what it costs.
class SubscriptionGraphNode extends Equatable {
  const SubscriptionGraphNode({
    required this.subscriptionId,
    required this.name,
    required this.provider,
    required this.monthlyCost,
    required this.memberCount,
    required this.yourShare,
    required this.isShared,
    required this.renewalDaysLeft,
    this.category,
  });

  final String subscriptionId;
  final String name;
  final String provider;
  final double monthlyCost;
  final int memberCount;
  final double yourShare;
  final bool isShared;
  final int renewalDaysLeft;
  final SubscriptionCategory? category;

  double get savingsFromSplit => isShared ? monthlyCost - yourShare : 0;

  @override
  List<Object?> get props => [
        subscriptionId,
        name,
        provider,
        monthlyCost,
        memberCount,
        yourShare,
        isShared,
        renewalDaysLeft,
        category,
      ];
}

enum InsightType {
  duplicateServices,
  highBurn,
  unusedShare,
  savingsOpportunity,
  renewalAlert,
  memberPending,
  general,
}

class SmartInsight extends Equatable {
  const SmartInsight({
    required this.type,
    required this.title,
    required this.message,
    this.severity = InsightSeverity.info,
    this.actionLabel,
  });

  final InsightType type;
  final String title;
  final String message;
  final InsightSeverity severity;
  final String? actionLabel;

  @override
  List<Object?> get props => [type, title, message, severity, actionLabel];
}

enum InsightSeverity { info, warning, critical, success }

class SubscriptionIntelligence extends Equatable {
  const SubscriptionIntelligence({
    required this.monthlyBurn,
    required this.yearlyBurn,
    required this.graph,
    required this.insights,
    required this.smartAlerts,
    required this.duplicateCategories,
    required this.totalSavingsFromSplits,
    required this.sharedSubscriptionCount,
  });

  final double monthlyBurn;
  final double yearlyBurn;
  final List<SubscriptionGraphNode> graph;
  final List<SmartInsight> insights;
  final List<SmartInsight> smartAlerts;
  final Map<String, int> duplicateCategories;
  final double totalSavingsFromSplits;
  final int sharedSubscriptionCount;

  @override
  List<Object?> get props => [
        monthlyBurn,
        yearlyBurn,
        graph,
        insights,
        smartAlerts,
        duplicateCategories,
        totalSavingsFromSplits,
        sharedSubscriptionCount,
      ];
}
