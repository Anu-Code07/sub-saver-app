import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsaver/core/network/dio_client.dart';
import 'package:subsaver/core/services/hive_service.dart';
import 'package:subsaver/core/services/network_info.dart';
import 'package:subsaver/core/utils/debt_simplifier.dart';
import 'package:subsaver/core/config/app_config.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/features/authentication/data/datasources/auth_datasource.dart';
import 'package:subsaver/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:subsaver/features/authentication/data/datasources/mock_auth_remote_datasource.dart';
import 'package:subsaver/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';
import 'package:subsaver/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/groups/data/repositories/group_repository_impl.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:subsaver/features/settlements/domain/usecases/settlement_usecases.dart';
import 'package:subsaver/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:subsaver/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:subsaver/core/services/notification_service.dart';
import 'package:subsaver/core/services/ocr_service.dart';
import 'package:subsaver/core/services/reminder_service.dart';
import 'package:subsaver/features/settlements/data/repositories/payment_proof_repository_impl.dart';
import 'package:subsaver/features/settlements/domain/repositories/payment_proof_repository.dart';
import 'package:subsaver/features/settlements/presentation/bloc/payment_proof_bloc.dart';
import 'package:subsaver/core/services/offline_sync_service.dart';
import 'package:subsaver/core/services/session_storage_service.dart';
import 'package:subsaver/core/services/biometric_auth_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => DioClient());

  // Core
  sl.registerLazySingleton(() => HiveService());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => const DebtSimplifier());
  sl.registerLazySingleton(() => SessionStorageService(sl()));
  sl.registerLazySingleton(() => BiometricAuthService());

  // Data sources
  sl.registerLazySingleton<AuthDataSource>(() {
    if (AppConfig.useMockAuth) {
      debugPrint('SubSavr: mock auth enabled — OTP is ${AppConstants.mockOtpCode}');
      return MockAuthRemoteDataSource();
    }
    return AuthRemoteDataSource(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    );
  });
  sl.registerLazySingleton(() => UserRemoteDataSource(firestore: sl(), storage: sl()));
  sl.registerLazySingleton(() => SubscriptionRemoteDataSource(sl()));
  sl.registerLazySingleton(() => GroupRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ExpenseRemoteDataSource(sl()));
  sl.registerLazySingleton(() => WalletRemoteDataSource(sl()));
  sl.registerLazySingleton(() => NotificationRemoteDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<SubscriptionRepository>(() => SubscriptionRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<GroupRepository>(() => GroupRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepositoryImpl(sl()));
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(sl()));
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()));
  sl.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepositoryImpl(sl()));
  sl.registerLazySingleton<AchievementRepository>(() => AchievementRepositoryImpl(sl()));
  sl.registerLazySingleton<PaymentProofRepository>(() => PaymentProofRepositoryImpl(sl(), sl()));

  // Use cases
  sl.registerLazySingleton(() => SignInWithPhone(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithApple(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => UnlockWithBiometric(sl()));
  sl.registerLazySingleton(() => RestoreTrustedSession(sl()));
  sl.registerLazySingleton(() => ClearTrustedSession(sl()));
  sl.registerLazySingleton(() => GetUserProfile(sl()));
  sl.registerLazySingleton(() => UpdateUserProfile(sl()));
  sl.registerLazySingleton(() => CreateSubscription(sl()));
  sl.registerLazySingleton(() => GetSubscriptions(sl()));
  sl.registerLazySingleton(() => GetDashboardStats(sl()));
  sl.registerLazySingleton(() => CreateGroup(sl()));
  sl.registerLazySingleton(() => JoinGroup(sl()));
  sl.registerLazySingleton(() => SimplifyDebts(sl()));
  sl.registerLazySingleton(() => SplitExpenseEqually());
  sl.registerLazySingleton(() => SplitExpenseByPercentage());
  sl.registerLazySingleton(() => SplitExpenseByCustom());

  // Services
  sl.registerLazySingleton(() => OcrService());
  sl.registerLazySingleton(() => ReminderService(sl()));
  sl.registerLazySingleton(() => NotificationService(sl<NotificationRepository>()));
  sl.registerLazySingleton(() => OfflineSyncService(sl(), sl(), sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(
        authRepository: sl(),
        signInWithPhone: sl(),
        verifyOtp: sl(),
        signInWithGoogle: sl(),
        signInWithApple: sl(),
        signOut: sl(),
        unlockWithBiometric: sl(),
        restoreTrustedSession: sl(),
        clearTrustedSession: sl(),
      ));
  sl.registerFactory(() => ProfileBloc(
        getUserProfile: sl(),
        updateUserProfile: sl(),
        userRepository: sl(),
      ));
  sl.registerFactory(() => DashboardBloc(
        getDashboardStats: sl(),
        subscriptionRepository: sl(),
        groupRepository: sl(),
      ));
  sl.registerFactory(() => SubscriptionListBloc(
        getSubscriptions: sl(),
        subscriptionRepository: sl(),
      ));
  sl.registerFactory(() => SubscriptionDetailBloc(repository: sl()));
  sl.registerFactory(() => CreateSubscriptionBloc(
        createSubscription: sl(),
        expenseRepository: sl(),
        splitEqually: sl(),
        splitByPercentage: sl(),
        splitByCustom: sl(),
      ));
  sl.registerFactory(() => GroupBloc(
        createGroup: sl(),
        joinGroup: sl(),
        groupRepository: sl(),
        expenseRepository: sl(),
      ));
  sl.registerFactory(() => SettlementBloc(simplifyDebts: sl(), expenseRepository: sl()));
  sl.registerFactory(() => PaymentProofBloc(
        ocrService: sl(),
        paymentProofRepository: sl(),
      ));
  sl.registerFactory(() => AnalyticsBloc(analyticsRepository: sl()));
  sl.registerFactory(() => NotificationBloc(notificationRepository: sl()));
  sl.registerFactory(() => WalletBloc(walletRepository: sl()));
  sl.registerFactory(() => ThemeCubit(sl<SharedPreferences>()));
}
