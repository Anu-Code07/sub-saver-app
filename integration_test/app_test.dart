import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:subsaver/core/utils/validators.dart';
import 'package:subsaver/core/utils/subscription_detector.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settlement flow logic', () {
    test('subscription detector categorizes Netflix as OTT', () {
      expect(SubscriptionDetector.detectCategory('Netflix Premium'), SubscriptionCategory.ott);
    });

    test('validators reject invalid phone', () {
      expect(Validators.phone('123'), isNotNull);
    });
  });
}
