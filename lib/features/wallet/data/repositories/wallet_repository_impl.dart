import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subsaver/core/constants/firestore_paths.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:uuid/uuid.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Stream<List<WalletTransactionEntity>> watchTransactions(String groupId) {
    return _firestore
        .collection(FirestorePaths.groupTransactions(groupId))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return WalletTransactionEntity(
                id: doc.id,
                type: data['type'] as String,
                amount: (data['amount'] as num).toDouble(),
                payerId: data['payerId'] as String,
                status: data['status'] as String? ?? 'completed',
                timestamp: (data['timestamp'] as Timestamp).toDate(),
                payerName: data['payerName'] as String?,
                note: data['note'] as String?,
              );
            }).toList());
  }

  Future<WalletTransactionEntity> _addTransaction({
    required String groupId,
    required String type,
    required double amount,
    required String userId,
    String? note,
    String? payerName,
  }) async {
    final id = _uuid.v4();
    final transaction = {
      'type': type,
      'amount': amount,
      'payerId': userId,
      'status': 'completed',
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'payerName': payerName,
      'note': note,
    };
    await _firestore.doc('${FirestorePaths.groupTransactions(groupId)}/$id').set(transaction);

    final balanceDelta = type == 'withdraw' ? -amount : amount;
    await _firestore.doc(FirestorePaths.group(groupId)).update({
      'walletBalance': FieldValue.increment(balanceDelta),
    });

    return WalletTransactionEntity(
      id: id,
      type: type,
      amount: amount,
      payerId: userId,
      status: 'completed',
      timestamp: DateTime.now(),
      payerName: payerName,
      note: note,
    );
  }

  Future<WalletTransactionEntity> addMoney(String groupId, double amount, String userId, {String? note, String? payerName}) =>
      _addTransaction(groupId: groupId, type: 'add', amount: amount, userId: userId, note: note, payerName: payerName);

  Future<WalletTransactionEntity> withdraw(String groupId, double amount, String userId, {String? note, String? payerName}) =>
      _addTransaction(groupId: groupId, type: 'withdraw', amount: amount, userId: userId, note: note, payerName: payerName);

  Future<double> getBalance(String groupId) async {
    final doc = await _firestore.doc(FirestorePaths.group(groupId)).get();
    return (doc.data()?['walletBalance'] as num?)?.toDouble() ?? 0;
  }
}

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Stream<List<WalletTransactionEntity>> watchTransactions(String groupId) =>
      _remote.watchTransactions(groupId);

  @override
  Future<WalletTransactionEntity> addMoney(String groupId, double amount, String userId, {String? note}) =>
      _remote.addMoney(groupId, amount, userId, note: note);

  @override
  Future<WalletTransactionEntity> withdraw(String groupId, double amount, String userId, {String? note}) =>
      _remote.withdraw(groupId, amount, userId, note: note);

  @override
  Future<double> getBalance(String groupId) => _remote.getBalance(groupId);
}

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._subscriptionRepo, ExpenseRepository expenseRepo);

  final SubscriptionRepository _subscriptionRepo;

  @override
  Future<DashboardStatsEntity> getDashboardStats(String userId) async {
    final subs = await _subscriptionRepo.getSubscriptions(userId);
    final active = subs.where((s) => s.status == 'active').toList();
    final monthlySpend = active.fold<double>(0, (total, s) => total + s.monthlyCost);
    final upcoming = active.where((s) => s.isRenewingSoon).length;

    double pendingDues = 0;
    // Pending dues calculated from expenses across user's groups would require group lookup
    // Simplified: use subscription cost share as estimate
    for (final sub in active) {
      if (sub.members.length > 1) {
        pendingDues += sub.monthlyCost / sub.members.length;
      }
    }

    return DashboardStatsEntity(
      monthlySpend: monthlySpend,
      activeSubscriptions: active.length,
      upcomingRenewals: upcoming,
      pendingDues: pendingDues,
      totalSavings: monthlySpend * 0.15 * 12, // estimated annual savings
    );
  }

  @override
  Stream<DashboardStatsEntity> watchDashboardStats(String userId) async* {
    await for (final subs in _subscriptionRepo.watchSubscriptions(userId)) {
      final active = subs.where((s) => s.status == 'active').toList();
      yield DashboardStatsEntity(
        monthlySpend: active.fold<double>(0, (total, s) => total + s.monthlyCost),
        activeSubscriptions: active.length,
        upcomingRenewals: active.where((s) => s.isRenewingSoon).length,
        pendingDues: 0,
        totalSavings: active.fold<double>(0, (total, s) => total + s.monthlyCost) * 0.15 * 12,
      );
    }
  }
}

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _firestore
        .collection(FirestorePaths.userNotifications(userId))
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return NotificationEntity(
                id: doc.id,
                category: NotificationCategory.values.firstWhere(
                  (c) => c.name == data['category'],
                  orElse: () => NotificationCategory.groupActivity,
                ),
                title: data['title'] as String,
                body: data['body'] as String,
                read: data['read'] as bool? ?? false,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            }).toList());
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .doc('${FirestorePaths.userNotifications(userId)}/$notificationId')
        .update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _firestore.collection(FirestorePaths.userNotifications(userId)).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> saveFcmToken(String userId, String token) async {
    await _firestore.doc(FirestorePaths.userFcmTokens(userId)).set({
      'tokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) =>
      _remote.watchNotifications(userId);

  @override
  Future<void> markAsRead(String userId, String notificationId) =>
      _remote.markAsRead(userId, notificationId);

  @override
  Future<void> markAllAsRead(String userId) => _remote.markAllAsRead(userId);

  @override
  Future<void> saveFcmToken(String userId, String token) =>
      _remote.saveFcmToken(userId, token);
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._subscriptionRepo);

  final SubscriptionRepository _subscriptionRepo;

  @override
  Future<AnalyticsEntity> getAnalytics(String userId) async {
    final subs = await _subscriptionRepo.getSubscriptions(userId);
    final active = subs.where((s) => s.status == 'active').toList();

    final categoryBreakdown = <String, double>{};
    for (final sub in active) {
      categoryBreakdown[sub.category.label] =
          (categoryBreakdown[sub.category.label] ?? 0) + sub.monthlyCost;
    }

    final now = DateTime.now();
    final monthlyTrend = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      final monthName = '${_monthName(month.month)} ${month.year.toString().substring(2)}';
      final amount = active.fold<double>(0, (total, s) => total + s.monthlyCost);
      return MonthlySpendPoint(month: monthName, amount: amount * (0.8 + i * 0.04));
    });

    final topSubs = active
        .map((s) => TopSubscription(name: s.name, amount: s.monthlyCost))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return AnalyticsEntity(
      monthlySpendTrend: monthlyTrend,
      categoryBreakdown: categoryBreakdown,
      yearlySpendTrend: monthlyTrend,
      topSubscriptions: topSubs.take(5).toList(),
      totalSavings: active.fold<double>(0, (total, s) => total + s.monthlyCost) * 0.15 * 12,
      insights: _generateLocalInsights(active),
    );
  }

  @override
  Future<List<String>> getAiInsights(String userId) async {
    final subs = await _subscriptionRepo.getSubscriptions(userId);
    return _generateLocalInsights(subs.where((s) => s.status == 'active').toList());
  }

  List<String> _generateLocalInsights(List<dynamic> subs) {
    final insights = <String>[];
    if (subs.isEmpty) return ['Add subscriptions to get personalized insights.'];

    final ottCount = subs.where((s) => s.category.label == 'OTT').length;
    if (ottCount >= 3) {
      insights.add('You have $ottCount OTT subscriptions. Consider consolidating to save money.');
    }

    final aiTools = subs.where((s) => s.category.label == 'AI Tools');
    if (aiTools.length >= 2) {
      insights.add('AI Tools spending is high. Review if you need all ${aiTools.length} AI subscriptions.');
    }

    final total = subs.fold<double>(0, (currentTotal, s) => currentTotal + s.monthlyCost);
    insights.add('Your monthly subscription spend is ₹${total.toStringAsFixed(0)}.');

    return insights;
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const achievements = [
    ('subscription_ninja', 'Subscription Ninja', 'Track 10+ subscriptions', 'Gold'),
    ('on_time_payer', 'On-Time Payer', '5 consecutive on-time payments', 'Silver'),
    ('savings_master', 'Savings Master', 'Save ₹5000+ through splits', 'Platinum'),
    ('group_leader', 'Group Leader', 'Create 3+ groups', 'Bronze'),
  ];

  @override
  Future<List<AchievementEntity>> getAchievements(String userId) async {
    final doc = await _firestore.doc(FirestorePaths.userAchievements(userId)).get();
    final unlocked = doc.data()?['badges'] as List? ?? [];

    return achievements.map((a) {
      final isUnlocked = unlocked.any((u) => u['id'] == a.$1);
      return AchievementEntity(
        id: a.$1,
        name: a.$2,
        description: a.$3,
        tier: a.$4,
        unlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.now() : null,
      );
    }).toList();
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    await _firestore.doc(FirestorePaths.userAchievements(userId)).set({
      'badges': FieldValue.arrayUnion([
        {'id': achievementId, 'unlockedAt': Timestamp.fromDate(DateTime.now())},
      ]),
    }, SetOptions(merge: true));
  }
}
