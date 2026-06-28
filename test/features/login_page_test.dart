import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subsaver/core/utils/validators.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';
import 'package:subsaver/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/pages/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Validators', () {
    test('phone validator accepts 10 digits', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('phone validator rejects short numbers', () {
      expect(Validators.phone('123'), isNotNull);
    });

    test('otp validator requires 6 digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12345'), isNotNull);
    });
  });

  testWidgets('LoginPage renders phone input and continue button', (tester) async {
    final mockRepo = MockAuthRepository();
    when(() => mockRepo.authStateChanges).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuthBloc(
            authRepository: mockRepo,
            signInWithPhone: SignInWithPhone(mockRepo),
            verifyOtp: VerifyOtp(mockRepo),
            signInWithGoogle: SignInWithGoogle(mockRepo),
            signInWithApple: SignInWithApple(mockRepo),
            signOut: SignOut(mockRepo),
          ),
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Continue with OTP'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
