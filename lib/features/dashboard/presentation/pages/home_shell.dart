import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/shimmer_loading.dart';
import 'package:subsaver/features/analytics/presentation/pages/analytics_page.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:subsaver/features/profile/presentation/pages/profile_page.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _onTabSelected(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onProfileTap: () => _onTabSelected(2)),
      AnalyticsPage(onProfileTap: () => _onTabSelected(2)),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F9FB),
      body: pages[_index],
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _index,
        onTap: _onTabSelected,
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<DashboardBloc>().add(DashboardLoadRequested(authState.user.id));
    }
  }

  UserEntity? _currentUser() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.user;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: DashboardGlassHeader(
              avatarUrl: user?.avatar,
              avatarInitial: user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : null,
              onMenuTap: () => context.push('/subscriptions'),
              onAvatarTap: widget.onProfileTap,
            ),
          ),
          Expanded(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.marginMobile),
                    child: ShimmerDashboard(),
                  );
                }
                if (state is DashboardError) {
                  return Center(child: Text(state.message));
                }
                if (state is DashboardLoaded) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _loadDashboard(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.stackMd,
                        AppSpacing.marginMobile,
                        100,
                      ),
                      children: [
                        Text(
                          'Manage\nsubscriptions 💸',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        _SubscriptionsSection(
                          subscriptions: state.recentSubscriptions,
                          monthlyTotal: state.stats.monthlySpend,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        const _HotDealsSection(),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  const _SubscriptionsSection({
    required this.subscriptions,
    required this.monthlyTotal,
  });

  final List<SubscriptionEntity> subscriptions;
  final double monthlyTotal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Your subscriptions',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            RichText(
              text: TextSpan(
                style: textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                children: [
                  const TextSpan(text: 'Total: '),
                  TextSpan(
                    text: CurrencyFormatter.format(monthlyTotal),
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: '/m',
                    style: textTheme.labelSmall?.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: subscriptions.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.stackMd),
            itemBuilder: (context, index) {
              if (index == subscriptions.length) {
                return AddSubscriptionCard(
                  onTap: () => context.push('/subscriptions/create'),
                );
              }
              final sub = subscriptions[index];
              return SubscriptionOverviewCard(
                subscription: sub,
                onTap: () => context.push('/subscriptions/${sub.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HotDealsSection extends StatelessWidget {
  const _HotDealsSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hot deals',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            const Text('🔥'),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        HotDealCard(
          provider: 'Apple Music',
          title: '3 months free',
          banner: const AppleMusicDealBanner(),
          metaIcon: Icons.schedule_outlined,
          metaText: '8 days left',
        ),
        const SizedBox(height: AppSpacing.stackMd),
        HotDealCard(
          provider: 'Skillshare',
          title: '2 months free',
          banner: const SkillshareDealBanner(),
          metaIcon: Icons.person_outline,
          metaText: '492 left',
        ),
      ],
    );
  }
}
