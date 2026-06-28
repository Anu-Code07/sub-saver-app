import 'package:flutter_test/flutter_test.dart';
import 'package:subsaver/core/utils/debt_simplifier.dart';

void main() {
  test('DebtSimplifier reduces circular debts', () {
    const simplifier = DebtSimplifier();
    final result = simplifier.simplify([
      const Debt(from: 'A', to: 'B', amount: 100),
      const Debt(from: 'B', to: 'C', amount: 100),
    ]);
    expect(result.length, 1);
    expect(result.first.from, 'A');
    expect(result.first.to, 'C');
    expect(result.first.amount, 100);
  });
}
