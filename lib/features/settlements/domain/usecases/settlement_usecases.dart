import 'package:dartz/dartz.dart';
import 'package:subsaver/core/errors/failures.dart';
import 'package:subsaver/core/utils/debt_simplifier.dart';
import 'package:subsaver/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';

class SimplifyDebts {
  SimplifyDebts(this._simplifier);

  final DebtSimplifier _simplifier;

  List<SettlementEntity> call(List<ExpenseEntity> expenses) {
    final debts = <Debt>[];

    for (final expense in expenses) {
      for (final split in expense.splits) {
        if (split.status == PaymentStatus.paid) continue;
        if (split.uid == expense.paidBy) continue;
        debts.add(Debt(from: split.uid, to: expense.paidBy, amount: split.amount));
      }
    }

    return _simplifier
        .simplify(debts)
        .map((d) => SettlementEntity(fromUserId: d.from, toUserId: d.to, amount: d.amount))
        .toList();
  }
}

class SplitExpenseEqually {
  List<SplitEntity> call({
    required double amount,
    required List<String> memberIds,
    List<String> memberNames = const [],
  }) {
    if (memberIds.isEmpty) return [];
    final share = double.parse((amount / memberIds.length).toStringAsFixed(2));
    return List.generate(memberIds.length, (i) {
      return SplitEntity(
        uid: memberIds[i],
        amount: share,
        status: PaymentStatus.pending,
        name: i < memberNames.length ? memberNames[i] : null,
      );
    });
  }
}

class SplitExpenseByPercentage {
  List<SplitEntity> call({required double amount, required Map<String, double> percentages}) {
    return percentages.entries
        .map((e) => SplitEntity(
              uid: e.key,
              amount: double.parse((amount * e.value / 100).toStringAsFixed(2)),
              status: PaymentStatus.pending,
            ))
        .toList();
  }
}

class SplitExpenseByCustom {
  List<SplitEntity> call({required Map<String, double> amounts, double? expectedTotal}) {
    final total = amounts.values.fold<double>(0, (a, b) => a + b);
    if (expectedTotal != null && (total - expectedTotal).abs() > 0.01) {
      throw ArgumentError('Custom amounts must total subscription cost');
    }
    return amounts.entries
        .map((e) => SplitEntity(uid: e.key, amount: e.value, status: PaymentStatus.pending))
        .toList();
  }
}

class CreateSubscription {
  CreateSubscription(this._repository);
  final SubscriptionRepository _repository;

  Future<Either<Failure, SubscriptionEntity>> call(SubscriptionEntity subscription) async {
    try {
      return Right(await _repository.createSubscription(subscription));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetSubscriptions {
  GetSubscriptions(this._repository);
  final SubscriptionRepository _repository;

  Future<Either<Failure, List<SubscriptionEntity>>> call(String userId) async {
    try {
      return Right(await _repository.getSubscriptions(userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetDashboardStats {
  GetDashboardStats(this._repository);
  final DashboardRepository _repository;

  Future<Either<Failure, DashboardStatsEntity>> call(String userId) async {
    try {
      return Right(await _repository.getDashboardStats(userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class CreateGroup {
  CreateGroup(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, GroupEntity>> call(GroupEntity group) async {
    try {
      return Right(await _repository.createGroup(group));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class JoinGroup {
  JoinGroup(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, GroupEntity>> call(String inviteCode, String userId) async {
    try {
      return Right(await _repository.joinGroup(inviteCode, userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
