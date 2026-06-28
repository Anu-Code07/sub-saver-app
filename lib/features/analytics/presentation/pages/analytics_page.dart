import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/widgets/shimmer_loading.dart';
import 'package:subsaver/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<AnalyticsBloc>().add(AnalyticsLoadRequested(auth.user.id));
    }
  }

  UserEntity? _currentUser() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.user;
    return null;
  }

  double _monthlyAverage(List<MonthlySpendPoint> points) {
    if (points.isEmpty) return 0;
    return points.map((p) => p.amount).reduce((a, b) => a + b) / points.length;
  }

  double _trendPercent(List<MonthlySpendPoint> points) {
    if (points.length < 2) return 0;
    final previous = points[points.length - 2].amount;
    final current = points.last.amount;
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AnalyticsGlassHeader(
              avatarUrl: user?.avatar,
              avatarInitial: user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : null,
              onAvatarTap: widget.onProfileTap,
            ),
          ),
          Expanded(
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.marginMobile),
                    child: ShimmerDashboard(),
                  );
                }
                if (state is AnalyticsError) {
                  return Center(child: Text(state.message));
                }
                if (state is AnalyticsLoaded) {
                  final analytics = state.analytics;
                  final monthlyAverage = _monthlyAverage(analytics.monthlySpendTrend);
                  final trend = _trendPercent(analytics.monthlySpendTrend);
                  final insightTitle = state.insights.isNotEmpty
                      ? _insightTitle(state.insights.first)
                      : 'Bundle your streaming services';
                  final insightBody = state.insights.isNotEmpty
                      ? state.insights.first
                      : 'Review overlapping subscriptions to find easy monthly savings.';

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _loadAnalytics(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.stackMd,
                        AppSpacing.marginMobile,
                        100,
                      ),
                      children: [
                        SpendingSummaryHeader(
                          monthlyAverage: monthlyAverage,
                          trendPercent: trend,
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        PremiumSpendChart(points: analytics.monthlySpendTrend),
                        const SizedBox(height: AppSpacing.stackLg),
                        Text(
                          'Category Breakdown',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        CategoryBreakdownGrid(breakdown: analytics.categoryBreakdown),
                        const SizedBox(height: AppSpacing.stackLg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saving Insights',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Explore',
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            boxShadow: AppShadows.card,
                          ),
                          child: SavingInsightCard(
                            title: insightTitle,
                            subtitle: insightBody,
                          ),
                        ),
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

  String _insightTitle(String insight) {
    if (insight.length <= 48) return insight;
    final sentenceEnd = insight.indexOf('.');
    if (sentenceEnd > 0 && sentenceEnd < 48) {
      return insight.substring(0, sentenceEnd);
    }
    return '${insight.substring(0, 45)}...';
  }
}
