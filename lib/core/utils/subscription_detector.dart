import 'package:subsaver/core/constants/subscription_categories.dart';

/// Rule-based subscription categorization (AI stub for Phase 2).
class SubscriptionDetector {
  static SubscriptionCategory detectCategory(String name) {
    final lower = name.toLowerCase();
    if (_matches(lower, ['netflix', 'prime', 'hotstar', 'disney', 'youtube', 'hulu', 'hbo'])) {
      return SubscriptionCategory.ott;
    }
    if (_matches(lower, ['spotify', 'apple music', 'gaana', 'wynk', 'jiosaavn'])) {
      return SubscriptionCategory.music;
    }
    if (_matches(lower, ['chatgpt', 'claude', 'copilot', 'gemini', 'midjourney'])) {
      return SubscriptionCategory.aiTools;
    }
    if (_matches(lower, ['notion', 'figma', 'microsoft', 'office', 'slack', 'zoom'])) {
      return SubscriptionCategory.productivity;
    }
    if (_matches(lower, ['xbox', 'playstation', 'steam', 'epic'])) {
      return SubscriptionCategory.gaming;
    }
    if (_matches(lower, ['coursera', 'udemy', 'skillshare', 'linkedin learning'])) {
      return SubscriptionCategory.education;
    }
    if (_matches(lower, ['internet', 'electricity', 'water', 'gas', 'wifi'])) {
      return SubscriptionCategory.utilities;
    }
    return SubscriptionCategory.utilities;
  }

  static BillingCycle detectBillingCycle(double monthlyEquivalent, double statedCost) {
    if ((statedCost - monthlyEquivalent).abs() < 1) return BillingCycle.monthly;
    if ((statedCost / 3 - monthlyEquivalent).abs() < 1) return BillingCycle.quarterly;
    if ((statedCost / 12 - monthlyEquivalent).abs() < 1) return BillingCycle.yearly;
    return BillingCycle.monthly;
  }

  static double suggestSplitAmount(double totalCost, int memberCount) {
    if (memberCount <= 0) return totalCost;
    return double.parse((totalCost / memberCount).toStringAsFixed(2));
  }

  static bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
