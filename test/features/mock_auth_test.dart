import 'package:flutter_test/flutter_test.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/features/authentication/data/datasources/mock_auth_remote_datasource.dart';

void main() {
  group('MockAuthRemoteDataSource', () {
    late MockAuthRemoteDataSource dataSource;

    setUp(() {
      dataSource = MockAuthRemoteDataSource();
    });

    test('signInWithPhone returns mock verification id', () async {
      final id = await dataSource.signInWithPhone('9876543210');
      expect(id, AppConstants.mockVerificationId);
    });

    test('verifyOtp accepts mock code and signs in demo user', () async {
      await dataSource.signInWithPhone('9876543210');

      final user = await dataSource.verifyOtp(
        AppConstants.mockVerificationId,
        AppConstants.mockOtpCode,
      );

      expect(user.phone, '+919876543210');
      expect(dataSource.currentUser?.id, user.id);
    });

    test('verifyOtp rejects wrong code', () async {
      await dataSource.signInWithPhone('9876543210');

      expect(
        () => dataSource.verifyOtp(AppConstants.mockVerificationId, '000000'),
        throwsA(isA<Exception>()),
      );
    });

    test('signOut clears current user', () async {
      await dataSource.signInWithPhone('9876543210');
      await dataSource.verifyOtp(AppConstants.mockVerificationId, AppConstants.mockOtpCode);

      await dataSource.signOut();

      expect(dataSource.currentUser, isNull);
    });
  });
}
