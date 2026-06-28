import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/router/app_router.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;

  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    await AppRouter.completeOnboarding();
    if (mounted) context.go('/login');
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          _SplitBillSlide(
            floatAnimation: _floatController,
            currentPage: _currentPage,
            onSkip: _finish,
            onNext: _next,
          ),
          _TrackEverythingSlide(
            floatAnimation: _floatController,
            currentPage: _currentPage,
            onNext: _next,
          ),
          _SplitEffortlesslySlide(
            floatAnimation: _floatController,
            currentPage: _currentPage,
            onSkip: _finish,
            onNext: _next,
          ),
        ],
      ),
    );
  }
}

// ─── Screen 1: Split bill with friends ───────────────────────────────────────

class _SplitBillSlide extends StatelessWidget {
  const _SplitBillSlide({
    required this.floatAnimation,
    required this.currentPage,
    required this.onSkip,
    required this.onNext,
  });

  final Animation<double> floatAnimation;
  final int currentPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C6EF0), AppColors.primary],
        ),
      ),
      child: Stack(
        children: [
          // Ambient floating shapes
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (_, __) {
              final t = floatAnimation.value;
              return Stack(
                children: [
                  Positioned(
                    top: -40 + t * 20,
                    left: -40 + t * 10,
                    child: _blurCircle(256, AppColors.primaryContainer.withValues(alpha: 0.4)),
                  ),
                  Positioned(
                    bottom: -20 - t * 15,
                    right: -20 - t * 10,
                    child: _blurCircle(320, AppColors.secondaryContainer.withValues(alpha: 0.35)),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.25,
                    right: 0,
                    child: _blurCircle(128, Colors.white.withValues(alpha: 0.15)),
                  ),
                ],
              );
            },
          ),
          // Dashed graph trace
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.33,
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(painter: _GraphTracePainter()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Skip',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Transform.rotate(
                    angle: -0.035,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadows.elevated,
                      ),
                      child: Text(
                        'Split bill',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'with your\nfriends and\nfamily',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                          fontSize: 36,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text(
                    'Manage your subscriptions with friends more easily — track, split, and settle in one place.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                  ),
                  const Spacer(),
                  _OnboardingPaginator(activeIndex: 0, currentPage: currentPage, light: true),
                  const SizedBox(height: 40),
                  Center(
                    child: _CircularNextButton(onPressed: onNext),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// ─── Screen 2: Track everything in one place ─────────────────────────────────

class _TrackEverythingSlide extends StatelessWidget {
  const _TrackEverythingSlide({
    required this.floatAnimation,
    required this.currentPage,
    required this.onNext,
  });

  final Animation<double> floatAnimation;
  final int currentPage;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.4,
          colors: [Color(0xFF6C5CE7), AppColors.primary, Color(0xFF5847D2)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _blurCircle(128, Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3,
            right: MediaQuery.of(context).size.width * 0.15,
            child: _blurCircle(192, AppColors.secondary.withValues(alpha: 0.2)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                  child: Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: floatAnimation,
                      builder: (_, __) => _SubscriptionCardStack(offset: floatAnimation.value),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    0,
                    AppSpacing.marginMobile,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track everything\nin one place',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              height: 1.05,
                              fontSize: 36,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        'A unified dashboard for your digital life. Manage, split, and discover subscriptions effortlessly.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OnboardingPaginator(activeIndex: 1, currentPage: currentPage, light: true),
                          _PillNextButton(onPressed: onNext),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _SubscriptionCardStack extends StatelessWidget {
  const _SubscriptionCardStack({required this.offset});

  final double offset;

  @override
  Widget build(BuildContext context) {
    final dy = (offset - 0.5) * 24;

    return SizedBox(
      width: 260,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, 48 + dy * 0.5),
            child: Transform.rotate(
              angle: -0.1,
              child: _GlassSubscriptionCard(
                brand: 'Disney+',
                icon: Icons.movie_outlined,
                iconColor: const Color(0xFF113CCF),
                opacity: 0.6,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -8 + dy * 0.3),
            child: Transform.rotate(
              angle: 0.05,
              child: _GlassSubscriptionCard(
                brand: 'Spotify',
                icon: Icons.music_note,
                iconColor: const Color(0xFF1DB954),
                opacity: 0.85,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -48 + dy),
            child: Transform.rotate(
              angle: -0.035,
              child: _GlassSubscriptionCard(
                brand: 'Netflix Premium',
                icon: Icons.play_circle_outline,
                iconColor: const Color(0xFFE50914),
                opacity: 1,
                showPrice: true,
                price: '₹649',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSubscriptionCard extends StatelessWidget {
  const _GlassSubscriptionCard({
    required this.brand,
    required this.icon,
    required this.iconColor,
    required this.opacity,
    this.showPrice = false,
    this.price,
  });

  final String brand;
  final IconData icon;
  final Color iconColor;
  final double opacity;
  final bool showPrice;
  final String? price;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 256,
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Text(
                      brand,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (showPrice && price != null) ...[
                  Text(
                    'MONTHLY BILLING',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          2,
                          (i) => Transform.translate(
                            offset: Offset(i == 0 ? 0 : -8, 0),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2 + i * 0.2),
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Active',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(height: 16, width: 100, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Container(height: 32, width: 140, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(8))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Screen 3: Split bills effortlessly ──────────────────────────────────────

class _SplitEffortlesslySlide extends StatelessWidget {
  const _SplitEffortlesslySlide({
    required this.floatAnimation,
    required this.currentPage,
    required this.onSkip,
    required this.onNext,
  });

  final Animation<double> floatAnimation;
  final int currentPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.background,
            AppColors.surfaceContainerLowest,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            right: -80,
            child: _blurCircle(256, AppColors.primary.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _blurCircle(320, AppColors.secondaryContainer.withValues(alpha: 0.1)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      TextButton(
                        onPressed: onSkip,
                        child: Text(
                          'Skip',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: floatAnimation,
                    builder: (_, __) {
                      final dy = (floatAnimation.value - 0.5) * 12;
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 320,
                            height: 320,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(320, 320),
                                  painter: _ConnectionLinesPainter(),
                                ),
                                Transform.translate(
                                  offset: Offset(0, dy),
                                  child: _CenterBillCard(),
                                ),
                                _SplitAvatar(
                                  top: 32,
                                  left: 24,
                                  initials: 'AK',
                                  color: const Color(0xFF6C5CE7),
                                  amount: '₹162',
                                  badgeAlign: Alignment.bottomRight,
                                ),
                                _SplitAvatar(
                                  top: 32,
                                  right: 24,
                                  initials: 'RM',
                                  color: const Color(0xFFFF7675),
                                  amount: '₹162',
                                  badgeAlign: Alignment.bottomLeft,
                                ),
                                _SplitAvatar(
                                  bottom: 32,
                                  left: 24,
                                  initials: 'PS',
                                  color: const Color(0xFF00CEC9),
                                  amount: '₹162',
                                  badgeAlign: Alignment.topRight,
                                ),
                                _SplitAvatar(
                                  bottom: 32,
                                  right: 24,
                                  initials: 'VN',
                                  color: const Color(0xFF5341CD),
                                  amount: '₹162',
                                  badgeAlign: Alignment.topLeft,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stackLg),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                            child: Column(
                              children: [
                                Text(
                                  'Split bills effortlessly',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        fontSize: 24,
                                        height: 1.2,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.stackSm),
                                Text(
                                  'Divide shared subscriptions and recurring payments with friends automatically every month.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    0,
                    AppSpacing.marginMobile,
                    48,
                  ),
                  child: Column(
                    children: [
                      _OnboardingPaginator(activeIndex: 2, currentPage: currentPage, light: false),
                      const SizedBox(height: AppSpacing.stackLg),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            shadowColor: AppColors.primary.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentPage == 2 ? 'Get Started' : 'Next',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _CenterBillCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 192,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'TOTAL BILL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2,
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹649',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.66,
                  minHeight: 4,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitAvatar extends StatelessWidget {
  const _SplitAvatar({
    required this.initials,
    required this.color,
    required this.amount,
    required this.badgeAlign,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final String initials;
  final Color color;
  final String amount;
  final Alignment badgeAlign;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 4),
              boxShadow: AppShadows.card,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          Positioned(
            bottom: badgeAlign == Alignment.bottomRight || badgeAlign == Alignment.bottomLeft ? -6 : null,
            top: badgeAlign == Alignment.topRight || badgeAlign == Alignment.topLeft ? -6 : null,
            right: badgeAlign == Alignment.bottomRight || badgeAlign == Alignment.topRight ? -4 : null,
            left: badgeAlign == Alignment.bottomLeft || badgeAlign == Alignment.topLeft ? -4 : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _OnboardingPaginator extends StatelessWidget {
  const _OnboardingPaginator({
    required this.activeIndex,
    required this.currentPage,
    required this.light,
  });

  final int activeIndex;
  final int currentPage;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final active = light ? Colors.white : AppColors.primary;
    final inactive = light ? Colors.white.withValues(alpha: 0.3) : AppColors.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 32 : 8,
          height: isActive ? 6 : 6,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

class _CircularNextButton extends StatefulWidget {
  const _CircularNextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CircularNextButton> createState() => _CircularNextButtonState();
}

class _CircularNextButtonState extends State<_CircularNextButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                return Container(
                  width: 80 + _pulse.value * 16,
                  height: 80 + _pulse.value * 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15 * (1 - _pulse.value)),
                  ),
                );
              },
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.primary, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillNextButton extends StatelessWidget {
  const _PillNextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom painters ─────────────────────────────────────────────────────────

class _GraphTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.cubicTo(
      size.width * 0.125,
      size.height * 0.7,
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.375,
      size.height * 0.7,
    );
    path.cubicTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.625,
      size.height * 0.3,
      size.width * 0.75,
      size.height * 0.5,
    );
    path.cubicTo(
      size.width * 0.875,
      size.height * 0.6,
      size.width * 0.95,
      size.height * 0.55,
      size.width,
      size.height * 0.4,
    );

    final dashed = _dashPath(path, const [8, 8]);
    canvas.drawPath(dashed, paint);

    canvas.drawCircle(Offset(size.width * 0.375, size.height * 0.7), 4, Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.5), 6, Paint()..color = Colors.white);
  }

  Path _dashPath(Path source, List<double> dashArray) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = dashArray[draw ? 0 : 1];
        if (draw) {
          dashed.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectionLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final points = [
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.75, size.height * 0.75),
    ];

    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawLine(center, point, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
