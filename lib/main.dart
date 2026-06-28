import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/router/app_router.dart';
import 'package:subsaver/core/services/hive_service.dart';
import 'package:subsaver/core/services/network_info.dart';
import 'package:subsaver/core/services/notification_service.dart';
import 'package:subsaver/core/services/offline_sync_service.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:subsaver/firebase_options.dart';
import 'package:subsaver/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase init failed: $e. Run flutterfire configure to set up Firebase.');
  }

  await di.initDependencies();
  await di.sl<HiveService>().init();
  di.sl<OfflineSyncService>().startListening();
  await di.sl<NotificationService>().init();

  runApp(const SubSavrApp());
}

class SubSavrApp extends StatefulWidget {
  const SubSavrApp({super.key});

  @override
  State<SubSavrApp> createState() => _SubSavrAppState();
}

class _SubSavrAppState extends State<SubSavrApp> {
  late final GoRouter _router;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create();
    di.sl<NetworkInfo>().onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    di.sl<ThemeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(const AuthCheckRequested())),
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider(create: (_) => di.sl<SubscriptionListBloc>()),
        BlocProvider(create: (_) => di.sl<SubscriptionDetailBloc>()),
        BlocProvider(create: (_) => di.sl<CreateSubscriptionBloc>()),
        BlocProvider(create: (_) => di.sl<GroupBloc>()),
        BlocProvider(create: (_) => di.sl<SettlementBloc>()),
        BlocProvider(create: (_) => di.sl<AnalyticsBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationBloc>()),
        BlocProvider(create: (_) => di.sl<WalletBloc>()),
        BlocProvider(create: (_) => di.sl<ThemeCubit>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            di.sl<NotificationService>().registerToken(state.user.id);
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final mode = themeState is ThemeLoaded ? themeState.mode : AppThemeMode.light;
            return MaterialApp.router(
              title: 'SubSavr',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: switch (mode) {
                AppThemeMode.dark => ThemeMode.dark,
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.system => ThemeMode.system,
              },
              routerConfig: _router,
              builder: (context, child) =>
                  ConnectivityBanner(isOnline: _isOnline, child: child ?? const SizedBox.shrink()),
            );
          },
        ),
      ),
    );
  }
}
