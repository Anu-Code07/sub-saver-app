import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  const DashboardStatsEntity({
    required this.monthlySpend,
    required this.activeSubscriptions,
    required this.upcomingRenewals,
    required this.pendingDues,
    required this.totalSavings,
  });

  final double monthlySpend;
  final int activeSubscriptions;
  final int upcomingRenewals;
  final double pendingDues;
  final double totalSavings;

  @override
  List<Object?> get props => [
        monthlySpend, activeSubscriptions, upcomingRenewals, pendingDues, totalSavings,
      ];
}
