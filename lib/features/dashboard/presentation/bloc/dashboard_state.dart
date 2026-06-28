import 'package:equatable/equatable.dart';
import 'package:subsaver/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:subsaver/features/dashboard/domain/entities/subscription_intelligence_entity.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

// Dashboard
sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(
    this.stats,
    this.recentSubscriptions,
    this.groups, {
    this.intelligence,
  });

  final DashboardStatsEntity stats;
  final List<SubscriptionEntity> recentSubscriptions;
  final List<GroupEntity> groups;
  final SubscriptionIntelligence? intelligence;

  @override
  List<Object?> get props => [stats, recentSubscriptions, groups, intelligence];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Subscription List
sealed class SubscriptionListState extends Equatable {
  const SubscriptionListState();
  @override
  List<Object?> get props => [];
}

class SubscriptionListInitial extends SubscriptionListState {
  const SubscriptionListInitial();
}

class SubscriptionListLoading extends SubscriptionListState {
  const SubscriptionListLoading();
}

class SubscriptionListLoaded extends SubscriptionListState {
  const SubscriptionListLoaded(this.subscriptions);
  final List<SubscriptionEntity> subscriptions;
  @override
  List<Object?> get props => [subscriptions];
}

class SubscriptionListError extends SubscriptionListState {
  const SubscriptionListError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Create Subscription
sealed class CreateSubscriptionState extends Equatable {
  const CreateSubscriptionState();
  @override
  List<Object?> get props => [];
}

class CreateSubscriptionInitial extends CreateSubscriptionState {
  const CreateSubscriptionInitial();
}

class CreateSubscriptionLoading extends CreateSubscriptionState {
  const CreateSubscriptionLoading();
}

class CreateSubscriptionSuccess extends CreateSubscriptionState {
  const CreateSubscriptionSuccess(this.subscription);
  final SubscriptionEntity subscription;
  @override
  List<Object?> get props => [subscription];
}

class CreateSubscriptionError extends CreateSubscriptionState {
  const CreateSubscriptionError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Group
sealed class GroupState extends Equatable {
  const GroupState();
  @override
  List<Object?> get props => [];
}

class GroupInitial extends GroupState {
  const GroupInitial();
}

class GroupLoading extends GroupState {
  const GroupLoading();
}

class GroupLoaded extends GroupState {
  const GroupLoaded(this.group, this.expenses, this.activity);
  final GroupEntity group;
  final List<ExpenseEntity> expenses;
  final List<ActivityEntity> activity;
  @override
  List<Object?> get props => [group, expenses, activity];
}

class GroupError extends GroupState {
  const GroupError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class GroupCreated extends GroupState {
  const GroupCreated(this.group);
  final GroupEntity group;
  @override
  List<Object?> get props => [group];
}

// Settlement
sealed class SettlementState extends Equatable {
  const SettlementState();
  @override
  List<Object?> get props => [];
}

class SettlementInitial extends SettlementState {
  const SettlementInitial();
}

class SettlementLoading extends SettlementState {
  const SettlementLoading();
}

class SettlementLoaded extends SettlementState {
  const SettlementLoaded(this.settlements);
  final List<SettlementEntity> settlements;
  @override
  List<Object?> get props => [settlements];
}

class SettlementError extends SettlementState {
  const SettlementError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Analytics
sealed class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded(this.analytics, this.insights);
  final AnalyticsEntity analytics;
  final List<String> insights;
  @override
  List<Object?> get props => [analytics, insights];
}

class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Notifications
sealed class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded(this.notifications);
  final List<NotificationEntity> notifications;
  @override
  List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  const NotificationError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Wallet
sealed class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  const WalletLoaded(this.balance, this.transactions);
  final double balance;
  final List<WalletTransactionEntity> transactions;
  @override
  List<Object?> get props => [balance, transactions];
}

class WalletError extends WalletState {
  const WalletError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Theme
sealed class ThemeState extends Equatable {
  const ThemeState();
  @override
  List<Object?> get props => [];
}

class ThemeLoaded extends ThemeState {
  const ThemeLoaded(this.mode);

  final AppThemeMode mode;

  bool get isDarkMode => mode == AppThemeMode.dark;

  @override
  List<Object?> get props => [mode];
}

enum AppThemeMode { light, dark, system }

// Subscription Detail
sealed class SubscriptionDetailState extends Equatable {
  const SubscriptionDetailState();
  @override
  List<Object?> get props => [];
}

class SubscriptionDetailInitial extends SubscriptionDetailState {
  const SubscriptionDetailInitial();
}

class SubscriptionDetailLoading extends SubscriptionDetailState {
  const SubscriptionDetailLoading();
}

class SubscriptionDetailLoaded extends SubscriptionDetailState {
  const SubscriptionDetailLoaded(this.subscription);
  final SubscriptionEntity subscription;
  @override
  List<Object?> get props => [subscription];
}

class SubscriptionDetailError extends SubscriptionDetailState {
  const SubscriptionDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class SubscriptionDetailActionSuccess extends SubscriptionDetailState {
  const SubscriptionDetailActionSuccess(this.message, {this.popRoute = false});
  final String message;
  final bool popRoute;
  @override
  List<Object?> get props => [message, popRoute];
}
