import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subsaver/core/utils/debt_simplifier.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';
import 'package:subsaver/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/settlements/domain/usecases/settlement_usecases.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('DebtSimplifier', () {
    const simplifier = DebtSimplifier();

    test('simplifies two-person debt', () {
      final result = simplifier.simplify([const Debt(from: 'A', to: 'B', amount: 250)]);
      expect(result, [const Debt(from: 'A', to: 'B', amount: 250)]);
    });

    test('simplifies circular debt chain', () {
      final result = simplifier.simplify([
        const Debt(from: 'A', to: 'B', amount: 100),
        const Debt(from: 'B', to: 'C', amount: 100),
      ]);
      expect(result.length, 1);
      expect(result.first.from, 'A');
      expect(result.first.to, 'C');
    });

    test('returns empty for no debts', () {
      expect(simplifier.simplify([]), isEmpty);
    });

    test('handles three-person complex debts', () {
      final result = simplifier.simplify([
        const Debt(from: 'A', to: 'B', amount: 300),
        const Debt(from: 'B', to: 'C', amount: 100),
        const Debt(from: 'C', to: 'A', amount: 50),
      ]);
      expect(result.isNotEmpty, true);
    });
  });

  group('SplitExpenseEqually', () {
    final useCase = SplitExpenseEqually();

    test('splits equally among 4 members', () {
      final splits = useCase.call(amount: 1000, memberIds: ['a', 'b', 'c', 'd']);
      expect(splits.length, 4);
      expect(splits.every((s) => s.amount == 250), true);
    });
  });

  group('SimplifyDebts use case', () {
    final useCase = SimplifyDebts(const DebtSimplifier());

    test('converts expenses to settlements', () {
      final expenses = [
        ExpenseEntity(
          id: '1',
          groupId: 'g1',
          subscriptionId: 's1',
          amount: 100,
          splitType: SplitType.equal,
          paidBy: 'B',
          splits: [
            const SplitEntity(uid: 'A', amount: 100, status: PaymentStatus.pending),
          ],
        ),
      ];
      final result = useCase(expenses);
      expect(result.length, 1);
      expect(result.first.fromUserId, 'A');
      expect(result.first.toUserId, 'B');
    });
  });

  group('AuthBloc', () {
    late MockAuthRepository mockRepo;
    late AuthBloc bloc;

    setUp(() {
      mockRepo = MockAuthRepository();
      when(() => mockRepo.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(() => mockRepo.currentUser).thenReturn(null);
      bloc = AuthBloc(
        authRepository: mockRepo,
        signInWithPhone: SignInWithPhone(mockRepo),
        verifyOtp: VerifyOtp(mockRepo),
        signInWithGoogle: SignInWithGoogle(mockRepo),
        signInWithApple: SignInWithApple(mockRepo),
        signOut: SignOut(mockRepo),
      );
    });

    tearDown(() => bloc.close());

    blocTest<AuthBloc, AuthState>(
      'emits AuthUnauthenticated when no user',
      build: () => bloc,
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthAuthenticated when user exists',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(const UserEntity(id: '1', name: 'Test'));
        return bloc;
      },
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [isA<AuthAuthenticated>()],
    );
  });
}
