import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';

class AnalyticsGlassHeader extends StatelessWidget {
  const AnalyticsGlassHeader({
    super.key,
    this.avatarUrl,
    this.avatarInitial,
    this.onAvatarTap,
  });

  final String? avatarUrl;
  final String? avatarInitial;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.stackMd,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withValues(alpha: 0.85),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppColors.primary, size: 26),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Text(
                  'Spending Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                ),
              ),
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl != null
                      ? Image.network(avatarUrl!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: AppColors.primaryFixed,
                          child: Center(
                            child: Text(
                              avatarInitial ?? '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpendingSummaryHeader extends StatelessWidget {
  const SpendingSummaryHeader({
    super.key,
    required this.monthlyAverage,
    required this.trendPercent,
  });

  final double monthlyAverage;
  final double trendPercent;

  @override
  Widget build(BuildContext context) {
    final isDecrease = trendPercent <= 0;
    final trendColor = isDecrease ? AppColors.tertiary : AppColors.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Average',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                CurrencyFormatter.format(monthlyAverage),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(
                  isDecrease ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trendPercent.abs().toStringAsFixed(0)}% ${isDecrease ? 'decrease' : 'increase'}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Text(
              'vs last month',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ],
    );
  }
}

class PremiumSpendChart extends StatelessWidget {
  const PremiumSpendChart({super.key, required this.points});

  final List<MonthlySpendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 256, child: Center(child: Text('No spending data yet')));
    }

    final spots = points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList();
    final peak = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final maxY = peak > 0 ? peak * 1.2 : 100.0;

    return Container(
      height: 256,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.surfaceVariant,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) {
                        final isLast = spot == spots.last;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 4,
                          color: isLast ? AppColors.primary : Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map(
                    (p) => Text(
                      p.month.split(' ').first.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.outlineVariant,
                            letterSpacing: 0.5,
                          ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBreakdownGrid extends StatelessWidget {
  const CategoryBreakdownGrid({super.key, required this.breakdown});

  final Map<String, double> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const _EmptyCategoryPlaceholder();
    }

    final total = breakdown.values.fold<double>(0, (sum, v) => sum + v);
    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final tiles = <Widget>[];
    for (var i = 0; i < sorted.length && i < 3; i++) {
      final entry = sorted[i];
      final percent = total > 0 ? (entry.value / total * 100).round() : 0;
      final style = _categoryStyle(entry.key, i);

      if (i == 2 && sorted.length >= 3) {
        tiles.add(_FeaturedCategoryCard(
          category: entry.key,
          amount: entry.value,
          icon: style.icon,
        ));
      } else {
        tiles.add(_CategoryTile(
          category: entry.key,
          amount: entry.value,
          percent: percent,
          icon: style.icon,
          iconBackground: style.background,
          iconColor: style.foreground,
        ));
      }
    }

    final accounted = sorted.take(3).fold<double>(0, (sum, e) => sum + e.value);
    final remaining = total - accounted;

    tiles.add(_CategoryTile(
      category: sorted.length > 3 ? 'Remaining' : _fourthCategoryLabel(sorted),
      amount: remaining > 0 ? remaining : (sorted.length > 3 ? remaining : 0),
      percent: total > 0 && remaining > 0 ? (remaining / total * 100).round() : null,
      icon: Icons.more_horiz,
      iconBackground: AppColors.surfaceContainerHighest,
      iconColor: AppColors.onSurfaceVariant,
    ));

    if (tiles.length < 4) {
      tiles.add(_CategoryTile(
        category: 'Remaining',
        amount: 0,
        icon: Icons.more_horiz,
        iconBackground: AppColors.surfaceContainerHighest,
        iconColor: AppColors.onSurfaceVariant,
      ));
    }

    return Column(
      children: [
        Row(
          children: [
            if (tiles.isNotEmpty) Expanded(child: tiles[0]),
            if (tiles.length > 1) ...[
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(child: tiles[1]),
            ],
          ],
        ),
        if (tiles.length > 2) ...[
          const SizedBox(height: AppSpacing.stackMd),
          tiles[2],
        ],
        if (tiles.length > 3) ...[
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              if (tiles.length > 3) Expanded(child: tiles[3]),
              if (tiles.length > 4) ...[
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(child: tiles[4]),
              ],
            ],
          ),
        ],
      ],
    );
  }

  String _fourthCategoryLabel(List<MapEntry<String, double>> sorted) {
    if (sorted.length > 3) return sorted[3].key;
    return 'Remaining';
  }
}

class SavingInsightCard extends StatelessWidget {
  const SavingInsightCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.lightbulb, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.amount,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.percent,
  });

  final String category;
  final double amount;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final int? percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (percent != null)
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            category,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCategoryCard extends StatelessWidget {
  const _FeaturedCategoryCard({
    required this.category,
    required this.amount,
    required this.icon,
  });

  final String category;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.8),
                          ),
                    ),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.onPrimary, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCategoryPlaceholder extends StatelessWidget {
  const _EmptyCategoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Text(
        'Add subscriptions to see category breakdown',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
      ),
    );
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.icon, this.background, this.foreground);

  final IconData icon;
  final Color background;
  final Color foreground;
}

_CategoryStyle _categoryStyle(String category, int index) {
  final key = category.toLowerCase();
  if (key.contains('ott') || key.contains('entertainment') || key.contains('music') || key.contains('gaming')) {
    return _CategoryStyle(Icons.movie, AppColors.primaryFixed, AppColors.primary);
  }
  if (key.contains('productivity') || key.contains('ai')) {
    return _CategoryStyle(Icons.work, const Color(0xFF5AF9F3), AppColors.tertiary);
  }
  if (key.contains('education')) {
    return _CategoryStyle(Icons.school, const Color(0xFFFFDAD8), AppColors.secondary);
  }
  if (key.contains('lifestyle') || key.contains('utilities') || key.contains('fitness')) {
    return _CategoryStyle(Icons.fitness_center, AppColors.primaryFixed, AppColors.primary);
  }
  return _CategoryStyle(
    Icons.category_outlined,
    index.isEven ? AppColors.primaryFixed : const Color(0xFF5AF9F3),
    index.isEven ? AppColors.primary : AppColors.tertiary,
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
