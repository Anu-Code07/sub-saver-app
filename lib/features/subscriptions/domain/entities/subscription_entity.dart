import 'package:equatable/equatable.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';

class SubscriptionEntity extends Equatable {
  const SubscriptionEntity({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    required this.cost,
    required this.renewalDate,
    required this.billingCycle,
    required this.createdBy,
    this.groupId,
    this.members = const [],
    this.status = 'active',
  });

  final String id;
  final String name;
  final String provider;
  final SubscriptionCategory category;
  final double cost;
  final DateTime renewalDate;
  final BillingCycle billingCycle;
  final String createdBy;
  final String? groupId;
  final List<String> members;
  final String status;

  double get monthlyCost => billingCycle.toMonthlyCost(cost);

  bool get isRenewingSoon {
    final days = renewalDate.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 7;
  }

  SubscriptionEntity copyWith({
    String? id,
    String? name,
    String? provider,
    SubscriptionCategory? category,
    double? cost,
    DateTime? renewalDate,
    BillingCycle? billingCycle,
    String? createdBy,
    String? groupId,
    List<String>? members,
    String? status,
  }) {
    return SubscriptionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      category: category ?? this.category,
      cost: cost ?? this.cost,
      renewalDate: renewalDate ?? this.renewalDate,
      billingCycle: billingCycle ?? this.billingCycle,
      createdBy: createdBy ?? this.createdBy,
      groupId: groupId ?? this.groupId,
      members: members ?? this.members,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id, name, provider, category, cost, renewalDate,
        billingCycle, createdBy, groupId, members, status,
      ];
}
