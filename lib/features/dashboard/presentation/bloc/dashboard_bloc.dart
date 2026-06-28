import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/core/utils/subscription_intelligence.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/settlements/domain/usecases/settlement_usecases.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetDashboardStats getDashboardStats,
    required SubscriptionRepository subscriptionRepository,
    required GroupRepository groupRepository,
    SubscriptionIntelligenceEngine? intelligenceEngine,
  })  : _getDashboardStats = getDashboardStats,
        _subscriptionRepository = subscriptionRepository,
        _groupRepository = groupRepository,
        _intelligenceEngine = intelligenceEngine ?? const SubscriptionIntelligenceEngine(),
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  final GetDashboardStats _getDashboardStats;
  final SubscriptionRepository _subscriptionRepository;
  final GroupRepository _groupRepository;
  final SubscriptionIntelligenceEngine _intelligenceEngine;

  Future<void> _onLoad(DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());
    final statsResult = await _getDashboardStats(event.userId);
    await statsResult.fold(
      (failure) async => emit(DashboardError(failure.message)),
      (stats) async {
        try {
          final subs = await _subscriptionRepository.getSubscriptions(event.userId);
          final groups = await _groupRepository.getGroups(event.userId);
          final intelligence = _intelligenceEngine.analyze(
            subscriptions: subs,
            groups: groups,
            currentUserId: event.userId,
          );
          emit(DashboardLoaded(stats, subs.take(5).toList(), groups, intelligence: intelligence));
        } catch (e) {
          emit(DashboardLoaded(stats, [], [], intelligence: null));
        }
      },
    );
  }
}

sealed class DashboardEvent {
  const DashboardEvent();
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested(this.userId);
  final String userId;
}

class SubscriptionListBloc extends Bloc<SubscriptionListEvent, SubscriptionListState> {
  SubscriptionListBloc({
    required GetSubscriptions getSubscriptions,
    required SubscriptionRepository subscriptionRepository,
  })  : _getSubscriptions = getSubscriptions,
        _subscriptionRepository = subscriptionRepository,
        super(const SubscriptionListInitial()) {
    on<SubscriptionListLoadRequested>(_onLoad);
    on<SubscriptionListWatchRequested>(_onWatch);
    on<SubscriptionDeleteRequested>(_onDelete);
  }

  final GetSubscriptions _getSubscriptions;
  final SubscriptionRepository _subscriptionRepository;
  StreamSubscription<dynamic>? _sub;

  Future<void> _onLoad(SubscriptionListLoadRequested event, Emitter<SubscriptionListState> emit) async {
    emit(const SubscriptionListLoading());
    final result = await _getSubscriptions(event.userId);
    result.fold(
      (failure) => emit(SubscriptionListError(failure.message)),
      (subs) => emit(SubscriptionListLoaded(subs)),
    );
  }

  Future<void> _onWatch(SubscriptionListWatchRequested event, Emitter<SubscriptionListState> emit) async {
    emit(const SubscriptionListLoading());
    await _sub?.cancel();
    _sub = _subscriptionRepository.watchSubscriptions(event.userId).listen(
      (subs) => emit(SubscriptionListLoaded(subs)),
      onError: (Object e) => emit(SubscriptionListError(e.toString())),
    );
  }

  Future<void> _onDelete(SubscriptionDeleteRequested event, Emitter<SubscriptionListState> emit) async {
    await _subscriptionRepository.deleteSubscription(event.subscriptionId);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

sealed class SubscriptionListEvent {
  const SubscriptionListEvent();
}

class SubscriptionListLoadRequested extends SubscriptionListEvent {
  const SubscriptionListLoadRequested(this.userId);
  final String userId;
}

class SubscriptionListWatchRequested extends SubscriptionListEvent {
  const SubscriptionListWatchRequested(this.userId);
  final String userId;
}

class SubscriptionDeleteRequested extends SubscriptionListEvent {
  const SubscriptionDeleteRequested(this.subscriptionId);
  final String subscriptionId;
}

class CreateSubscriptionBloc extends Bloc<CreateSubscriptionEvent, CreateSubscriptionState> {
  CreateSubscriptionBloc({
    required CreateSubscription createSubscription,
    required ExpenseRepository expenseRepository,
    required SplitExpenseEqually splitEqually,
    required SplitExpenseByPercentage splitByPercentage,
    required SplitExpenseByCustom splitByCustom,
  })  : _createSubscription = createSubscription,
        _expenseRepository = expenseRepository,
        _splitEqually = splitEqually,
        _splitByPercentage = splitByPercentage,
        _splitByCustom = splitByCustom,
        super(const CreateSubscriptionInitial()) {
    on<CreateSubscriptionSubmitted>(_onSubmit);
  }

  final CreateSubscription _createSubscription;
  final ExpenseRepository _expenseRepository;
  final SplitExpenseEqually _splitEqually;
  final SplitExpenseByPercentage _splitByPercentage;
  final SplitExpenseByCustom _splitByCustom;

  Future<void> _onSubmit(CreateSubscriptionSubmitted event, Emitter<CreateSubscriptionState> emit) async {
    emit(const CreateSubscriptionLoading());
    final result = await _createSubscription(event.subscription);
    await result.fold(
      (failure) async => emit(CreateSubscriptionError(failure.message)),
      (sub) async {
        if (event.groupId != null && event.splitType != null) {
          try {
            final splits = switch (event.splitType!) {
              SplitType.equal => _splitEqually(amount: sub.cost, memberIds: sub.members),
              SplitType.percentage => _splitByPercentage(amount: sub.cost, percentages: event.percentages ?? {}),
              SplitType.custom => _splitByCustom(amounts: event.customAmounts ?? {}, expectedTotal: sub.cost),
            };
            await _expenseRepository.createExpense(ExpenseEntity(
              id: '',
              groupId: event.groupId!,
              subscriptionId: sub.id,
              amount: sub.cost,
              splitType: event.splitType!,
              splits: splits,
              paidBy: sub.createdBy,
              subscriptionName: sub.name,
            ));
          } catch (e) {
            emit(CreateSubscriptionError('Subscription created but split failed: $e'));
            return;
          }
        }
        emit(CreateSubscriptionSuccess(sub));
      },
    );
  }
}

sealed class CreateSubscriptionEvent {
  const CreateSubscriptionEvent();
}

class CreateSubscriptionSubmitted extends CreateSubscriptionEvent {
  const CreateSubscriptionSubmitted(
    this.subscription, {
    this.groupId,
    this.splitType,
    this.percentages,
    this.customAmounts,
  });

  final SubscriptionEntity subscription;
  final String? groupId;
  final SplitType? splitType;
  final Map<String, double>? percentages;
  final Map<String, double>? customAmounts;
}

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  GroupBloc({
    required CreateGroup createGroup,
    required JoinGroup joinGroup,
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _createGroup = createGroup,
        _joinGroup = joinGroup,
        _groupRepository = groupRepository,
        _expenseRepository = expenseRepository,
        super(const GroupInitial()) {
    on<GroupCreateRequested>(_onCreate);
    on<GroupJoinRequested>(_onJoin);
    on<GroupLoadRequested>(_onLoad);
    on<GroupRemoveMemberRequested>(_onRemoveMember);
  }

  final CreateGroup _createGroup;
  final JoinGroup _joinGroup;
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  Future<void> _onCreate(GroupCreateRequested event, Emitter<GroupState> emit) async {
    emit(const GroupLoading());
    final result = await _createGroup(event.group);
    result.fold(
      (failure) => emit(GroupError(failure.message)),
      (group) => emit(GroupCreated(group)),
    );
  }

  Future<void> _onJoin(GroupJoinRequested event, Emitter<GroupState> emit) async {
    emit(const GroupLoading());
    final result = await _joinGroup(event.inviteCode, event.userId);
    result.fold(
      (failure) => emit(GroupError(failure.message)),
      (group) => emit(GroupLoaded(group, [], [])),
    );
  }

  Future<void> _onLoad(GroupLoadRequested event, Emitter<GroupState> emit) async {
    emit(const GroupLoading());
    try {
      final expenses = await _expenseRepository.watchExpenses(event.groupId).first;
      final activity = await _groupRepository.watchActivity(event.groupId).first;
      emit(GroupLoaded(event.group, expenses, activity));
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Future<void> _onRemoveMember(GroupRemoveMemberRequested event, Emitter<GroupState> emit) async {
    try {
      await _groupRepository.removeMember(event.groupId, event.memberId);
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }
}

sealed class GroupEvent {
  const GroupEvent();
}

class GroupCreateRequested extends GroupEvent {
  const GroupCreateRequested(this.group);
  final GroupEntity group;
}

class GroupJoinRequested extends GroupEvent {
  const GroupJoinRequested(this.inviteCode, this.userId);
  final String inviteCode;
  final String userId;
}

class GroupLoadRequested extends GroupEvent {
  const GroupLoadRequested(this.groupId, this.group);
  final String groupId;
  final GroupEntity group;
}

class GroupRemoveMemberRequested extends GroupEvent {
  const GroupRemoveMemberRequested(this.groupId, this.memberId);
  final String groupId;
  final String memberId;
}

class SettlementBloc extends Bloc<SettlementEvent, SettlementState> {
  SettlementBloc({
    required SimplifyDebts simplifyDebts,
    required ExpenseRepository expenseRepository,
  })  : _simplifyDebts = simplifyDebts,
        _expenseRepository = expenseRepository,
        super(const SettlementInitial()) {
    on<SettlementLoadRequested>(_onLoad);
    on<SettlementMarkPaid>(_onMarkPaid);
  }

  final SimplifyDebts _simplifyDebts;
  final ExpenseRepository _expenseRepository;

  Future<void> _onLoad(SettlementLoadRequested event, Emitter<SettlementState> emit) async {
    emit(const SettlementLoading());
    try {
      final expenses = await _expenseRepository.getExpenses(event.groupId);
      final settlements = _simplifyDebts(expenses);
      emit(SettlementLoaded(settlements));
    } catch (e) {
      emit(SettlementError(e.toString()));
    }
  }

  Future<void> _onMarkPaid(SettlementMarkPaid event, Emitter<SettlementState> emit) async {
    await _expenseRepository.updateSplitStatus(
      event.groupId,
      event.expenseId,
      event.userId,
      PaymentStatus.paid,
    );
    add(SettlementLoadRequested(event.groupId));
  }
}

sealed class SettlementEvent {
  const SettlementEvent();
}

class SettlementLoadRequested extends SettlementEvent {
  const SettlementLoadRequested(this.groupId);
  final String groupId;
}

class SettlementMarkPaid extends SettlementEvent {
  const SettlementMarkPaid({required this.groupId, required this.expenseId, required this.userId});
  final String groupId;
  final String expenseId;
  final String userId;
}

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc({required AnalyticsRepository analyticsRepository})
      : _analyticsRepository = analyticsRepository,
        super(const AnalyticsInitial()) {
    on<AnalyticsLoadRequested>(_onLoad);
  }

  final AnalyticsRepository _analyticsRepository;

  Future<void> _onLoad(AnalyticsLoadRequested event, Emitter<AnalyticsState> emit) async {
    emit(const AnalyticsLoading());
    try {
      final analytics = await _analyticsRepository.getAnalytics(event.userId);
      final insights = await _analyticsRepository.getAiInsights(event.userId);
      emit(AnalyticsLoaded(analytics, insights));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}

sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

class AnalyticsLoadRequested extends AnalyticsEvent {
  const AnalyticsLoadRequested(this.userId);
  final String userId;
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(const NotificationInitial()) {
    on<NotificationWatchRequested>(_onWatch);
    on<NotificationMarkRead>(_onMarkRead);
  }

  final NotificationRepository _notificationRepository;
  StreamSubscription<dynamic>? _sub;

  Future<void> _onWatch(NotificationWatchRequested event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    await _sub?.cancel();
    _sub = _notificationRepository.watchNotifications(event.userId).listen(
      (notifications) => emit(NotificationLoaded(notifications)),
      onError: (Object e) => emit(NotificationError(e.toString())),
    );
  }

  Future<void> _onMarkRead(NotificationMarkRead event, Emitter<NotificationState> emit) async {
    await _notificationRepository.markAsRead(event.userId, event.notificationId);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

sealed class NotificationEvent {
  const NotificationEvent();
}

class NotificationWatchRequested extends NotificationEvent {
  const NotificationWatchRequested(this.userId);
  final String userId;
}

class NotificationMarkRead extends NotificationEvent {
  const NotificationMarkRead(this.userId, this.notificationId);
  final String userId;
  final String notificationId;
}

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoad);
    on<WalletAddMoney>(_onAddMoney);
  }

  final WalletRepository _walletRepository;
  StreamSubscription<dynamic>? _txSub;

  Future<void> _onLoad(WalletLoadRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final balance = await _walletRepository.getBalance(event.groupId);
      await _txSub?.cancel();
      _txSub = _walletRepository.watchTransactions(event.groupId).listen(
        (txs) => emit(WalletLoaded(balance, txs)),
      );
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onAddMoney(WalletAddMoney event, Emitter<WalletState> emit) async {
    await _walletRepository.addMoney(event.groupId, event.amount, event.userId, note: event.note);
  }

  @override
  Future<void> close() {
    _txSub?.cancel();
    return super.close();
  }
}

sealed class WalletEvent {
  const WalletEvent();
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested(this.groupId);
  final String groupId;
}

class WalletAddMoney extends WalletEvent {
  const WalletAddMoney({required this.groupId, required this.amount, required this.userId, this.note});
  final String groupId;
  final double amount;
  final String userId;
  final String? note;
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._prefs) : super(const ThemeLoaded(AppThemeMode.light));

  final SharedPreferences _prefs;

  Future<void> load() async {
    final stored = _prefs.getString('theme_mode_v2') ?? 'light';
    emit(ThemeLoaded(AppThemeMode.values.byName(stored)));
  }

  Future<void> setMode(AppThemeMode mode) async {
    await _prefs.setString('theme_mode_v2', mode.name);
    emit(ThemeLoaded(mode));
  }

  Future<void> toggle() async {
    final current = state is ThemeLoaded ? (state as ThemeLoaded).mode : AppThemeMode.light;
    final next = current == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setMode(next);
  }
}

class SubscriptionDetailBloc extends Bloc<SubscriptionDetailEvent, SubscriptionDetailState> {
  SubscriptionDetailBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionDetailInitial()) {
    on<SubscriptionDetailLoadRequested>(_onLoad);
    on<SubscriptionDetailUpdateRequested>(_onUpdate);
    on<SubscriptionDetailCancelRequested>(_onCancel);
    on<SubscriptionDetailLeaveRequested>(_onLeave);
    on<SubscriptionDetailRemoveMemberRequested>(_onRemoveMember);
    on<SubscriptionDetailDeleteRequested>(_onDelete);
  }

  final SubscriptionRepository _repository;

  Future<void> _onLoad(SubscriptionDetailLoadRequested event, Emitter<SubscriptionDetailState> emit) async {
    emit(const SubscriptionDetailLoading());
    try {
      final sub = await _repository.getSubscription(event.id);
      emit(SubscriptionDetailLoaded(sub));
    } catch (e) {
      emit(SubscriptionDetailError(e.toString()));
    }
  }

  Future<void> _onUpdate(SubscriptionDetailUpdateRequested event, Emitter<SubscriptionDetailState> emit) async {
    try {
      final updated = await _repository.updateSubscription(event.subscription);
      emit(SubscriptionDetailLoaded(updated));
      emit(const SubscriptionDetailActionSuccess('Subscription updated'));
    } catch (e) {
      emit(SubscriptionDetailError(e.toString()));
    }
  }

  Future<void> _onCancel(SubscriptionDetailCancelRequested event, Emitter<SubscriptionDetailState> emit) async {
    try {
      await _repository.cancelSubscription(event.id);
      emit(const SubscriptionDetailActionSuccess('Subscription cancelled', popRoute: true));
    } catch (e) {
      emit(SubscriptionDetailError(e.toString()));
    }
  }

  Future<void> _onLeave(SubscriptionDetailLeaveRequested event, Emitter<SubscriptionDetailState> emit) async {
    try {
      await _repository.leaveSubscription(event.subscriptionId, event.userId);
      emit(const SubscriptionDetailActionSuccess('Left subscription', popRoute: true));
    } catch (e) {
      emit(SubscriptionDetailError(e.toString()));
    }
  }

  Future<void> _onRemoveMember(SubscriptionDetailRemoveMemberRequested event, Emitter<SubscriptionDetailState> emit) async {
    try {
      await _repository.removeMember(event.subscriptionId, event.memberId);
      final sub = await _repository.getSubscription(event.subscriptionId);
      emit(SubscriptionDetailLoaded(sub));
      emit(const SubscriptionDetailActionSuccess('Member removed'));
    } catch (e) {
      emit(SubscriptionDetailError(e.toString()));
    }
  }

  Future<void> _onDelete(SubscriptionDetailDeleteRequested event, Emitter<SubscriptionDetailState> emit) async {
    try {
      await _repository.deleteSubscription(event.id);
      emit(const SubscriptionDetailActionSuccess('Subscription deleted', popRoute: true));
    } catch (e) {
      emit(SubscriptionDetailError(e.toString()));
    }
  }
}

sealed class SubscriptionDetailEvent {
  const SubscriptionDetailEvent();
}

class SubscriptionDetailLoadRequested extends SubscriptionDetailEvent {
  const SubscriptionDetailLoadRequested(this.id);
  final String id;
}

class SubscriptionDetailUpdateRequested extends SubscriptionDetailEvent {
  const SubscriptionDetailUpdateRequested(this.subscription);
  final SubscriptionEntity subscription;
}

class SubscriptionDetailCancelRequested extends SubscriptionDetailEvent {
  const SubscriptionDetailCancelRequested(this.id);
  final String id;
}

class SubscriptionDetailLeaveRequested extends SubscriptionDetailEvent {
  const SubscriptionDetailLeaveRequested(this.subscriptionId, this.userId);
  final String subscriptionId;
  final String userId;
}

class SubscriptionDetailRemoveMemberRequested extends SubscriptionDetailEvent {
  const SubscriptionDetailRemoveMemberRequested(this.subscriptionId, this.memberId);
  final String subscriptionId;
  final String memberId;
}

class SubscriptionDetailDeleteRequested extends SubscriptionDetailEvent {
  const SubscriptionDetailDeleteRequested(this.id);
  final String id;
}
