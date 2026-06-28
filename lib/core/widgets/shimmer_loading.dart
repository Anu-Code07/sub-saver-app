import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainer,
      highlightColor: AppColors.surfaceContainerLow,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}

class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.surfaceContainer,
            highlightColor: AppColors.surfaceContainerLow,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ...List.generate(4, (_) => const ShimmerListTile()),
        ],
      ),
    );
  }
}
