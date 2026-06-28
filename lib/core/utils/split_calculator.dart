import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';

class SplitCalculator {
  static List<SplitEntity> equal({
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

  static List<SplitEntity> byPercentage({
    required double amount,
    required Map<String, double> percentages,
    Map<String, String> names = const {},
  }) {
    final total = percentages.values.fold<double>(0, (a, b) => a + b);
    if ((total - 100).abs() > 0.01) {
      throw ArgumentError('Percentages must total 100');
    }
    return percentages.entries.map((e) {
      return SplitEntity(
        uid: e.key,
        amount: double.parse((amount * e.value / 100).toStringAsFixed(2)),
        status: PaymentStatus.pending,
        name: names[e.key],
      );
    }).toList();
  }

  static List<SplitEntity> byCustom({
    required Map<String, double> amounts,
    Map<String, String> names = const {},
    double? expectedTotal,
  }) {
    final total = amounts.values.fold<double>(0, (a, b) => a + b);
    if (expectedTotal != null && (total - expectedTotal).abs() > 0.01) {
      throw ArgumentError('Custom amounts must total subscription cost');
    }
    return amounts.entries.map((e) {
      return SplitEntity(
        uid: e.key,
        amount: e.value,
        status: PaymentStatus.pending,
        name: names[e.key],
      );
    }).toList();
  }
}
