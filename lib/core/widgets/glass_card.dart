import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.onTap,
    this.borderRadius = AppRadius.xl,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated ? AppShadows.card : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: isDark
                ? AppColors.surfaceContainerHigh.withValues(alpha: 0.85)
                : AppColors.glassWhite,
            child: InkWell(
              onTap: onTap != null
                  ? () {
                      HapticFeedback.lightImpact();
                      onTap!();
                    }
                  : null,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isDark ? AppColors.outlineVariant.withValues(alpha: 0.3) : AppColors.glassBorder,
                    width: 0.5,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
