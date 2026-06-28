class FirestorePaths {
  static String user(String uid) => 'users/$uid';
  static String userFcmTokens(String uid) => 'users/$uid/fcmTokens';
  static String subscription(String id) => 'subscriptions/$id';
  static String group(String id) => 'groups/$id';
  static String groupExpenses(String groupId) => 'groups/$groupId/expenses';
  static String groupExpense(String groupId, String expenseId) =>
      'groups/$groupId/expenses/$expenseId';
  static String groupTransactions(String groupId) =>
      'groups/$groupId/transactions';
  static String groupActivity(String groupId) => 'groups/$groupId/activity';
  static String userNotifications(String uid) => 'notifications/$uid/items';
  static String userAchievements(String uid) => 'userAchievements/$uid';
  static String paymentProof(String id) => 'paymentProofs/$id';
  static String paymentProofs() => 'paymentProofs';
  static String subscriptionMembers(String subId) => 'subscriptions/$subId/members';
  static String recurringExpenses(String subId) => 'subscriptions/$subId/recurringExpenses';
}
