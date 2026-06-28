import 'package:subsaver/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionEntity>> getSubscriptions(String userId);
  Stream<List<SubscriptionEntity>> watchSubscriptions(String userId);
  Future<SubscriptionEntity> getSubscription(String id);
  Future<SubscriptionEntity> createSubscription(SubscriptionEntity subscription);
  Future<SubscriptionEntity> updateSubscription(SubscriptionEntity subscription);
  Future<void> deleteSubscription(String id);
  Future<void> leaveSubscription(String subscriptionId, String userId);
  Future<void> removeMember(String subscriptionId, String memberId);
  Future<void> cancelSubscription(String id);
}

abstract class GroupRepository {
  Future<List<GroupEntity>> getGroups(String userId);
  Stream<List<GroupEntity>> watchGroups(String userId);
  Future<GroupEntity> getGroup(String id);
  Future<GroupEntity> createGroup(GroupEntity group);
  Future<GroupEntity> joinGroup(String inviteCode, String userId);
  Future<void> removeMember(String groupId, String memberId);
  Future<void> transferOwnership(String groupId, String newOwnerId);
  Stream<List<ActivityEntity>> watchActivity(String groupId);
  Future<void> addActivity(ActivityEntity activity);
}

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getExpenses(String groupId);
  Stream<List<ExpenseEntity>> watchExpenses(String groupId);
  Future<ExpenseEntity> createExpense(ExpenseEntity expense);
  Future<void> updateSplitStatus(String groupId, String expenseId, String uid, PaymentStatus status);
}

abstract class WalletRepository {
  Stream<List<WalletTransactionEntity>> watchTransactions(String groupId);
  Future<WalletTransactionEntity> addMoney(String groupId, double amount, String userId, {String? note});
  Future<WalletTransactionEntity> withdraw(String groupId, double amount, String userId, {String? note});
  Future<double> getBalance(String groupId);
}

abstract class DashboardRepository {
  Future<DashboardStatsEntity> getDashboardStats(String userId);
  Stream<DashboardStatsEntity> watchDashboardStats(String userId);
}

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> watchNotifications(String userId);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> saveFcmToken(String userId, String token);
}

abstract class AnalyticsRepository {
  Future<AnalyticsEntity> getAnalytics(String userId);
  Future<List<String>> getAiInsights(String userId);
}

abstract class AchievementRepository {
  Future<List<AchievementEntity>> getAchievements(String userId);
  Future<void> unlockAchievement(String userId, String achievementId);
}
