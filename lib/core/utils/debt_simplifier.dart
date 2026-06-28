import 'package:equatable/equatable.dart';

/// Represents a directed debt: [from] owes [to] [amount].
class Debt extends Equatable {
  const Debt({required this.from, required this.to, required this.amount});

  final String from;
  final String to;
  final double amount;

  @override
  List<Object?> get props => [from, to, amount];
}

/// Graph-based debt minimization using greedy min-cash-flow algorithm.
/// Same approach used by Splitwise.
class DebtSimplifier {
  const DebtSimplifier();

  /// Simplifies a list of debts into minimum transactions.
  List<Debt> simplify(List<Debt> debts) {
    if (debts.isEmpty) return [];

    final balances = <String, double>{};

    for (final debt in debts) {
      if (debt.amount <= 0) continue;
      balances[debt.from] = (balances[debt.from] ?? 0) - debt.amount;
      balances[debt.to] = (balances[debt.to] ?? 0) + debt.amount;
    }

    final creditors = <_Balance>[];
    final debtors = <_Balance>[];

    for (final entry in balances.entries) {
      if (entry.value.abs() < 0.01) continue;
      if (entry.value > 0) {
        creditors.add(_Balance(entry.key, entry.value));
      } else {
        debtors.add(_Balance(entry.key, -entry.value));
      }
    }

    final result = <Debt>[];
    var i = 0;
    var j = 0;

    while (i < debtors.length && j < creditors.length) {
      final amount = debtors[i].amount < creditors[j].amount
          ? debtors[i].amount
          : creditors[j].amount;

      if (amount > 0.01) {
        result.add(Debt(
          from: debtors[i].userId,
          to: creditors[j].userId,
          amount: double.parse(amount.toStringAsFixed(2)),
        ));
      }

      debtors[i] = _Balance(debtors[i].userId, debtors[i].amount - amount);
      creditors[j] = _Balance(creditors[j].userId, creditors[j].amount - amount);

      if (debtors[i].amount < 0.01) i++;
      if (creditors[j].amount < 0.01) j++;
    }

    return result;
  }
}

class _Balance {
  const _Balance(this.userId, this.amount);
  final String userId;
  final double amount;
}
