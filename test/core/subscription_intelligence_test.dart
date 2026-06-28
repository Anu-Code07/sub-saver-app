import 'package:flutter_test/flutter_test.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/utils/subscription_intelligence.dart';
import 'package:subsaver/features/dashboard/domain/entities/subscription_intelligence_entity.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

void main() {
  const engine = SubscriptionIntelligenceEngine();

  group('SubscriptionIntelligenceEngine', () {
    test('detects duplicate OTT services', () {
      final subs = [
        SubscriptionEntity(
          id: '1',
          name: 'Netflix',
          provider: 'Netflix',
          category: SubscriptionCategory.ott,
          cost: 649,
          renewalDate: DateTime.now().add(const Duration(days: 10)),
          billingCycle: BillingCycle.monthly,
          createdBy: 'user1',
        ),
        SubscriptionEntity(
          id: '2',
          name: 'Prime Video',
          provider: 'Prime',
          category: SubscriptionCategory.ott,
          cost: 299,
          renewalDate: DateTime.now().add(const Duration(days: 15)),
          billingCycle: BillingCycle.monthly,
          createdBy: 'user1',
        ),
        SubscriptionEntity(
          id: '3',
          name: 'JioHotstar',
          provider: 'Hotstar',
          category: SubscriptionCategory.ott,
          cost: 299,
          renewalDate: DateTime.now().add(const Duration(days: 20)),
          billingCycle: BillingCycle.monthly,
          createdBy: 'user1',
        ),
      ];

      final result = engine.analyze(subscriptions: subs, groups: [], currentUserId: 'user1');

      expect(result.duplicateCategories['OTT'], 3);
      expect(
        result.insights.any((i) => i.type == InsightType.duplicateServices),
        isTrue,
      );
    });

    test('builds subscription graph with shared splits', () {
      final subs = [
        SubscriptionEntity(
          id: '1',
          name: 'Netflix',
          provider: 'Netflix',
          category: SubscriptionCategory.ott,
          cost: 649,
          renewalDate: DateTime.now().add(const Duration(days: 5)),
          billingCycle: BillingCycle.monthly,
          createdBy: 'user1',
          members: ['user1', 'user2', 'user3', 'user4'],
        ),
      ];

      final result = engine.analyze(subscriptions: subs, groups: [], currentUserId: 'user1');

      expect(result.graph.length, 1);
      expect(result.graph.first.isShared, isTrue);
      expect(result.graph.first.yourShare, 162.25);
      expect(result.graph.first.savingsFromSplit, closeTo(486.75, 0.01));
      expect(result.sharedSubscriptionCount, 1);
    });

    test('generates renewal alerts within 7 days', () {
      final subs = [
        SubscriptionEntity(
          id: '1',
          name: 'Spotify',
          provider: 'Spotify',
          category: SubscriptionCategory.music,
          cost: 299,
          renewalDate: DateTime.now().add(const Duration(days: 3)),
          billingCycle: BillingCycle.monthly,
          createdBy: 'user1',
          members: ['user1', 'user2'],
        ),
      ];

      final result = engine.analyze(subscriptions: subs, groups: [], currentUserId: 'user1');

      expect(
        result.smartAlerts.any((a) => a.type == InsightType.renewalAlert),
        isTrue,
      );
    });

    test('empty subscriptions prompts discovery insight', () {
      final result = engine.analyze(subscriptions: [], groups: [], currentUserId: 'user1');
      expect(result.insights.first.title, 'Discover your subscriptions');
    });
  });
}
