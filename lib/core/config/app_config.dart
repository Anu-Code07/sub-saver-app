import 'package:flutter/foundation.dart';

class AppConfig {
  // TODO(release): Set [alwaysShowOnboarding] to false so onboarding only shows on first launch.
  static const bool alwaysShowOnboarding = true;

  /// Mock phone OTP in debug builds (no Firebase SMS required).
  /// Disable with: flutter run --dart-define=MOCK_AUTH=false
  static bool get useMockAuth {
    if (!kDebugMode) return false;
    return const bool.fromEnvironment('MOCK_AUTH', defaultValue: true);
  }
}
