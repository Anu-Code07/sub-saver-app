class AppConstants {
  static const String appName = 'SubSavr';
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';

  // Hive boxes
  static const String subscriptionsBox = 'subscriptions';
  static const String groupsBox = 'groups';
  static const String expensesBox = 'expenses';
  static const String pendingWritesBox = 'pending_writes';
  static const String userBox = 'user';

  // Mock auth (debug)
  static const String mockVerificationId = 'mock-verification-id';
  static const String mockOtpCode = '123456';

  // SharedPreferences keys
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeModeKey = 'theme_mode';
  static const String currencyKey = 'currency';
  static const String notificationSettingsKey = 'notification_settings';
  static const String biometricEnabledKey = 'biometric_enabled';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String subscriptionsCollection = 'subscriptions';
  static const String groupsCollection = 'groups';
  static const String notificationsCollection = 'notifications';
  static const String achievementsCollection = 'userAchievements';

  // Renewal reminder days
  static const List<int> renewalReminderDays = [7, 3, 1, 0];

  // Free tier limits
  static const int freeGroupLimit = 3;
}
