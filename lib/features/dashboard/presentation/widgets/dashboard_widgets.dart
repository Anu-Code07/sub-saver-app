import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

class DashboardGlassHeader extends StatelessWidget {
  const DashboardGlassHeader({
    super.key,
    this.avatarUrl,
    this.avatarInitial,
    this.onMenuTap,
    this.onAvatarTap,
  });

  final String? avatarUrl;
  final String? avatarInitial;
  final VoidCallback? onMenuTap;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onMenuTap,
                child: const Icon(Icons.dashboard_outlined, color: AppColors.onSurface, size: 26),
              ),
              GestureDetector(
                onTap: onAvatarTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(
                    width: 40,
                    height: 40,
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
                                  fontSize: 16,
                                ),
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

class SubscriptionOverviewCard extends StatelessWidget {
  const SubscriptionOverviewCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  final SubscriptionEntity subscription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = _providerBrand(subscription.provider);
    final daysUntil = subscription.renewalDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(brand.icon, color: brand.color, size: 22),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              subscription.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatter.format(subscription.monthlyCost),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(width: 2),
                Text(
                  '/month',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              _paymentLabel(daysUntil),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class AddSubscriptionCard extends StatelessWidget {
  const AddSubscriptionCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.outlineVariant, width: 2, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.outline, size: 28),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Add new',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class HotDealCard extends StatelessWidget {
  const HotDealCard({
    super.key,
    required this.provider,
    required this.title,
    required this.banner,
    required this.metaIcon,
    required this.metaText,
    this.onTap,
  });

  final String provider;
  final String title;
  final Widget banner;
  final IconData metaIcon;
  final String metaText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 128, width: double.infinity, child: banner),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Row(
                    children: [
                      Icon(metaIcon, size: 16, color: AppColors.outline),
                      const SizedBox(width: AppSpacing.stackSm),
                      Text(
                        metaText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppleMusicDealBanner extends StatelessWidget {
  const AppleMusicDealBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEC4899), Color(0xFF9333EA)],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 36),
          ),
        ),
      ],
    );
  }
}

class SkillshareDealBanner extends StatelessWidget {
  const SkillshareDealBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF002333)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SKILL',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              Text(
                'SHARE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 0.9,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Instagram-style floating bottom navigation: a detached, rounded, blurred
/// pill that sits above the screen edge with an animated selected highlight.
class SubSavrNavBar extends StatelessWidget {
  const SubSavrNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavDestination>[
    _NavDestination(
      label: 'Home',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance,
    ),
    _NavDestination(
      label: 'Insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    _NavDestination(
      label: 'Profile',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 12 + (bottomInset > 0 ? 4 : 8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _items.length; i++)
                  _NavItem(
                    destination: _items[i],
                    selected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 240),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: selected ? AppColors.primary : AppColors.outline,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        destination.label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderBrand {
  const _ProviderBrand(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_ProviderBrand _providerBrand(String provider) {
  final key = provider.toLowerCase();
  if (key.contains('netflix')) {
    return const _ProviderBrand(Icons.play_circle_filled, Color(0xFFE50914));
  }
  if (key.contains('spotify')) {
    return const _ProviderBrand(Icons.music_note, Color(0xFF1DB954));
  }
  if (key.contains('disney')) {
    return const _ProviderBrand(Icons.movie, Color(0xFF113CCF));
  }
  if (key.contains('apple')) {
    return const _ProviderBrand(Icons.music_note, Color(0xFFFC3C44));
  }
  return const _ProviderBrand(Icons.subscriptions_outlined, AppColors.primary);
}

String _paymentLabel(int daysUntil) {
  if (daysUntil < 0) return 'Payment overdue';
  if (daysUntil == 0) return 'Payment due today';
  return 'Payment in: $daysUntil days';
}
