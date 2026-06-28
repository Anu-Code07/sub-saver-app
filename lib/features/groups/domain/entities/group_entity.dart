import 'package:equatable/equatable.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';

class GroupMemberEntity extends Equatable {
  const GroupMemberEntity({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.name,
    this.avatar,
  });

  final String uid;
  final GroupRole role;
  final DateTime joinedAt;
  final String? name;
  final String? avatar;

  @override
  List<Object?> get props => [uid, role, joinedAt, name, avatar];
}

class GroupEntity extends Equatable {
  const GroupEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.members,
    this.walletBalance = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final List<GroupMemberEntity> members;
  final double walletBalance;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, ownerId, inviteCode, members, walletBalance, createdAt];
}

class SplitEntity extends Equatable {
  const SplitEntity({
    required this.uid,
    required this.amount,
    required this.status,
    this.name,
  });

  final String uid;
  final double amount;
  final PaymentStatus status;
  final String? name;

  @override
  List<Object?> get props => [uid, amount, status, name];
}

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.subscriptionId,
    required this.amount,
    required this.splitType,
    required this.splits,
    required this.paidBy,
    this.subscriptionName,
    this.createdAt,
  });

  final String id;
  final String groupId;
  final String subscriptionId;
  final double amount;
  final SplitType splitType;
  final List<SplitEntity> splits;
  final String paidBy;
  final String? subscriptionName;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id, groupId, subscriptionId, amount, splitType, splits, paidBy, subscriptionName, createdAt,
      ];
}

class ActivityEntity extends Equatable {
  const ActivityEntity({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  final String id;
  final String type;
  final String actorId;
  final String actorName;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [id, type, actorId, actorName, message, timestamp, metadata];
}

class WalletTransactionEntity extends Equatable {
  const WalletTransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.payerId,
    required this.status,
    required this.timestamp,
    this.payerName,
    this.note,
  });

  final String type;
  final String id;
  final double amount;
  final String payerId;
  final String status;
  final DateTime timestamp;
  final String? payerName;
  final String? note;

  @override
  List<Object?> get props => [id, type, amount, payerId, status, timestamp, payerName, note];
}

class SettlementEntity extends Equatable {
  const SettlementEntity({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.fromUserName,
    this.toUserName,
  });

  final String fromUserId;
  final String toUserId;
  final double amount;
  final String? fromUserName;
  final String? toUserName;

  @override
  List<Object?> get props => [fromUserId, toUserId, amount, fromUserName, toUserName];
}


class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, category, title, body, read, createdAt];
}

class AnalyticsEntity extends Equatable {
  const AnalyticsEntity({
    required this.monthlySpendTrend,
    required this.categoryBreakdown,
    required this.yearlySpendTrend,
    required this.topSubscriptions,
    required this.totalSavings,
    required this.insights,
  });

  final List<MonthlySpendPoint> monthlySpendTrend;
  final Map<String, double> categoryBreakdown;
  final List<MonthlySpendPoint> yearlySpendTrend;
  final List<TopSubscription> topSubscriptions;
  final double totalSavings;
  final List<String> insights;

  @override
  List<Object?> get props => [
        monthlySpendTrend, categoryBreakdown, yearlySpendTrend,
        topSubscriptions, totalSavings, insights,
      ];
}

class MonthlySpendPoint extends Equatable {
  const MonthlySpendPoint({required this.month, required this.amount});

  final String month;
  final double amount;

  @override
  List<Object?> get props => [month, amount];
}

class TopSubscription extends Equatable {
  const TopSubscription({required this.name, required this.amount});

  final String name;
  final double amount;

  @override
  List<Object?> get props => [name, amount];
}

class AchievementEntity extends Equatable {
  const AchievementEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String tier;
  final bool unlocked;
  final DateTime? unlockedAt;

  @override
  List<Object?> get props => [id, name, description, tier, unlocked, unlockedAt];
}
