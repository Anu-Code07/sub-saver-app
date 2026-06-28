import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/config/app_config.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/validators.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      context.read<AuthBloc>().add(AuthPhoneSubmitted(_phoneController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthOtpSent) {
                  context.push('/otp', extra: {
                    'verificationId': state.verificationId,
                    'phoneNumber': state.phoneNumber,
                  });
                } else if (state is AuthAuthenticated) {
                  context.go('/home');
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    _BrandHeader(),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Access your shared subscriptions\nand savings dashboard.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    if (AppConfig.useMockAuth) ...[
                      _DevBanner(),
                      const SizedBox(height: 16),
                    ],
                    _GlassLoginCard(
                      formKey: _formKey,
                      phoneController: _phoneController,
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 28),
                    _SignUpFooter(),
                    const SizedBox(height: 16),
                    _LegalFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ambient blurred blobs + floating glass elements that mimic the FinTrack mock.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: Stack(
          children: [
            _Blob(
              top: -160,
              left: -96,
              size: 360,
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
            ),
            _Blob(
              bottom: -120,
              right: -64,
              size: 320,
              color: AppColors.tertiaryAccent.withValues(alpha: 0.30),
            ),
            _Blob(
              top: 280,
              left: 120,
              size: 260,
              color: AppColors.secondaryContainer.withValues(alpha: 0.18),
            ),
            const Positioned(
              top: 160,
              left: 28,
              child: _FloatingGlass(size: 60, radius: 18),
            ),
            const Positioned(
              bottom: 180,
              right: 32,
              child: _FloatingGlass(size: 88, radius: 44),
            ),
            const Positioned(
              top: 360,
              right: -16,
              child: _FloatingGlass(size: 110, radius: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _FloatingGlass extends StatefulWidget {
  const _FloatingGlass({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  State<_FloatingGlass> createState() => _FloatingGlassState();
}

class _FloatingGlassState extends State<_FloatingGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
      builder: (context, child) {
        final offset = (_controller.value - 0.5) * 24;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.trending_up,
              color: AppColors.onPrimary, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}

class _DevBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Dev mode: enter any 10-digit phone, then OTP ${AppConstants.mockOtpCode}',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppColors.onPrimaryFixedVariant),
      ),
    );
  }
}

class _GlassLoginCard extends StatelessWidget {
  const _GlassLoginCard({
    required this.formKey,
    required this.phoneController,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    prefixText: '+91 ',
                    hintText: '9876543210',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: Validators.phone,
                  onFieldSubmitted: (_) => onSubmit(),
                ),
                const SizedBox(height: 24),
                _GradientButton(onSubmit: onSubmit),
                const SizedBox(height: 24),
                const _OrDivider(),
                const SizedBox(height: 20),
                _SocialRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue with OTP',
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            size: 18, color: AppColors.onPrimary),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: AppColors.outlineVariant.withValues(alpha: 0.4))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.outline),
          ),
        ),
        Expanded(
            child: Divider(
                color: AppColors.outlineVariant.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthGoogleSignInRequested()),
          ),
        ),
        if (Platform.isIOS) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _SocialButton(
              icon: Icons.apple,
              label: 'Apple',
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthAppleSignInRequested()),
            ),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton(
      {required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.7),
          side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onSurface, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignUpFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: textTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          'Sign up',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: AppColors.outline);
    return Column(
      children: [
        Text('© 2026 ${AppConstants.appName}. All rights reserved.',
            style: style),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Privacy Policy', style: style),
            Text('  •  ', style: style),
            Text('Terms of Service', style: style),
          ],
        ),
      ],
    );
  }
}
