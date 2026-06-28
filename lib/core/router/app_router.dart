import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/core/config/app_config.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/authentication/presentation/pages/login_page.dart';
import 'package:subsaver/features/authentication/presentation/pages/otp_page.dart';
import 'package:subsaver/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:subsaver/features/onboarding/presentation/pages/splash_page.dart';
import 'package:subsaver/features/dashboard/presentation/pages/home_shell.dart';
import 'package:subsaver/features/subscriptions/presentation/pages/subscription_list_page.dart';
import 'package:subsaver/features/subscriptions/presentation/pages/subscription_detail_page.dart';
import 'package:subsaver/features/subscriptions/presentation/pages/create_subscription_page.dart';
import 'package:subsaver/features/subscriptions/presentation/pages/gmail_import_page.dart';
import 'package:subsaver/features/groups/presentation/pages/group_details_page.dart';
import 'package:subsaver/features/groups/presentation/pages/create_group_page.dart';
import 'package:subsaver/features/groups/presentation/pages/join_group_page.dart';
import 'package:subsaver/features/settlements/presentation/pages/settlement_page.dart';
import 'package:subsaver/features/wallet/presentation/pages/wallet_page.dart';
import 'package:subsaver/features/analytics/presentation/pages/analytics_page.dart';
import 'package:subsaver/features/notifications/presentation/pages/notifications_page.dart';
import 'package:subsaver/features/profile/presentation/pages/profile_page.dart';
import 'package:subsaver/features/profile/presentation/pages/settings_page.dart';
import 'package:subsaver/features/premium/presentation/pages/premium_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsaver/injection_container.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static bool get _showOnboardingOnLaunch => AppConfig.alwaysShowOnboarding;

  static GoRouter create() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: _showOnboardingOnLaunch ? '/onboarding' : '/',
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isAuth = authState is AuthAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp' ||
            state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/';

        if (!isAuth && !isAuthRoute) return '/login';
        // TODO(release): Restore full redirect when [AppConfig.alwaysShowOnboarding] is false.
        if (isAuth && state.matchedLocation == '/login') return '/home';
        if (isAuth &&
            state.matchedLocation == '/' &&
            !AppConfig.alwaysShowOnboarding) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(
          path: '/otp',
          builder: (_, state) {
            final extra = state.extra as Map<String, String>?;
            return OtpPage(
              verificationId: extra?['verificationId'] ?? '',
              phoneNumber: extra?['phoneNumber'] ?? '',
            );
          },
        ),
        GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
        GoRoute(path: '/subscriptions', builder: (_, __) => const SubscriptionListPage()),
        GoRoute(path: '/subscriptions/create', builder: (_, __) => const CreateSubscriptionPage()),
        GoRoute(path: '/subscriptions/import', builder: (_, __) => const GmailImportPage()),
        GoRoute(
          path: '/subscriptions/:id',
          builder: (_, state) => SubscriptionDetailPage(id: state.pathParameters['id']!),
        ),
        GoRoute(path: '/groups/create', builder: (_, __) => const CreateGroupPage()),
        GoRoute(path: '/groups/join', builder: (_, __) => const JoinGroupPage()),
        GoRoute(
          path: '/groups/:id',
          builder: (_, state) => GroupDetailsPage(groupId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/groups/:id/settle',
          builder: (_, state) => SettlementPage(groupId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/groups/:id/wallet',
          builder: (_, state) => WalletPage(groupId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsPage()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        GoRoute(path: '/premium', builder: (_, __) => const PremiumPage()),
      ],
    );
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = sl<SharedPreferences>();
    return prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(AppConstants.onboardingCompleteKey, false);
  }
}
