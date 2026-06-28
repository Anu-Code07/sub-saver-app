import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:subsaver/core/config/app_config.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/router/app_router.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.7, end: 1).animate(
    CurvedAnimation(parent: _intro, curve: const Interval(0, 0.7, curve: Curves.easeOutBack)),
  );

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    if (AppConfig.alwaysShowOnboarding) {
      context.go('/onboarding');
      return;
    }
    final onboardingDone = await AppRouter.isOnboardingComplete();
    if (!mounted) return;
    context.go(onboardingDone ? '/login' : '/onboarding');
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryContainer,
              AppColors.primaryFixedDim,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => CustomPaint(
                  painter: _RadiatingRingsPainter(progress: _pulse.value),
                ),
              ),
            ),
            const _FloatingShapes(),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LogoMark(),
                      const SizedBox(height: 28),
                      Text(
                        AppConstants.appName,
                        style: textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Split subscriptions,\nnot friendships',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your wallet…',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Icon(LucideIcons.wallet, size: 52, color: AppColors.primary),
    );
  }
}

class _FloatingShapes extends StatefulWidget {
  const _FloatingShapes();

  @override
  State<_FloatingShapes> createState() => _FloatingShapesState();
}

class _FloatingShapesState extends State<_FloatingShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          children: [
            _shape(top: 120, left: 36, offset: t, child: const Icon(Icons.star_rounded, color: Colors.white, size: 30)),
            _shape(top: 180, right: 44, offset: 1 - t, child: _triangle()),
            _shape(top: 320, left: 28, offset: 1 - t, child: _ring(18)),
            _shape(bottom: 220, right: 36, offset: t, child: const Icon(Icons.star_rounded, color: Colors.white, size: 16)),
            _shape(bottom: 300, left: 52, offset: t, child: _dot()),
            _shape(top: 260, right: 80, offset: t, child: _dot()),
          ],
        );
      },
    );
  }

  Widget _shape({double? top, double? bottom, double? left, double? right, required double offset, required Widget child}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.translate(
        offset: Offset(0, (offset - 0.5) * 24),
        child: Opacity(opacity: 0.85, child: child),
      ),
    );
  }

  Widget _triangle() => Transform.rotate(
        angle: 0.4,
        child: CustomPaint(size: const Size(26, 26), painter: _TrianglePainter()),
      );

  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        ),
      );

  Widget _dot() => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.tertiaryAccent;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadiatingRingsPainter extends CustomPainter {
  _RadiatingRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.7;
    const ringCount = 5;

    for (var i = 0; i < ringCount; i++) {
      final phase = (progress + i / ringCount) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1 - phase) * 0.18;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiatingRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
