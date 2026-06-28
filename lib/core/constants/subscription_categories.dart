enum SubscriptionCategory {
  ott('OTT'),
  music('Music'),
  aiTools('AI Tools'),
  productivity('Productivity'),
  gaming('Gaming'),
  education('Education'),
  utilities('Utilities');

  const SubscriptionCategory(this.label);
  final String label;

  static SubscriptionCategory fromString(String value) {
    return SubscriptionCategory.values.firstWhere(
      (c) => c.label.toLowerCase() == value.toLowerCase() || c.name == value,
      orElse: () => SubscriptionCategory.utilities,
    );
  }
}

enum BillingCycle {
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  const BillingCycle(this.label);
  final String label;

  static BillingCycle fromString(String value) {
    return BillingCycle.values.firstWhere(
      (c) => c.label.toLowerCase() == value.toLowerCase() || c.name == value,
      orElse: () => BillingCycle.monthly,
    );
  }

  double toMonthlyCost(double cost) {
    switch (this) {
      case BillingCycle.monthly:
        return cost;
      case BillingCycle.quarterly:
        return cost / 3;
      case BillingCycle.yearly:
        return cost / 12;
    }
  }
}

enum PaymentStatus {
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue'),
  partiallyPaid('Partially Paid');

  const PaymentStatus(this.label);
  final String label;
}

enum SplitType {
  equal('Equal'),
  percentage('Percentage'),
  custom('Custom');

  const SplitType(this.label);
  final String label;
}

enum GroupRole {
  owner('Owner'),
  admin('Admin'),
  member('Member');

  const GroupRole(this.label);
  final String label;
}

enum NotificationCategory {
  dueReminder('Due Reminder'),
  renewalReminder('Renewal Reminder'),
  groupActivity('Group Activity'),
  paymentReceived('Payment Received');

  const NotificationCategory(this.label);
  final String label;
}

enum AiTone {
  friendly('Friendly'),
  professional('Professional'),
  funny('Funny'),
  aggressive('Aggressive'),
  passiveAggressive('Passive Aggressive');

  const AiTone(this.label);
  final String label;
}
