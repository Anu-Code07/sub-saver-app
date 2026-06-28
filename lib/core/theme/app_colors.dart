import 'package:flutter/material.dart';

/// Premium FinTrack design tokens — light-first subscription fintech palette.
class AppColors {
  // Surfaces
  static const Color background = Color(0xFFF4FAFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFD4DBDD);
  static const Color surfaceBright = Color(0xFFF4FAFD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEEF5F7);
  static const Color surfaceContainer = Color(0xFFE8EFF1);
  static const Color surfaceContainerHigh = Color(0xFFE2E9EC);
  static const Color surfaceContainerHighest = Color(0xFFDDE4E6);
  static const Color surfaceVariant = Color(0xFFDDE4E6);

  // Content
  static const Color onSurface = Color(0xFF161D1F);
  static const Color onSurfaceVariant = Color(0xFF474554);
  static const Color onBackground = Color(0xFF161D1F);
  static const Color outline = Color(0xFF787586);
  static const Color outlineVariant = Color(0xFFC8C4D7);

  // Inverse (dark chrome)
  static const Color inverseSurface = Color(0xFF2B3234);
  static const Color inverseOnSurface = Color(0xFFEBF2F4);

  // Primary — royal purple
  static const Color primary = Color(0xFF5341CD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6C5CE7);
  static const Color onPrimaryContainer = Color(0xFFFAF6FF);
  static const Color inversePrimary = Color(0xFFC6BFFF);
  static const Color primaryFixed = Color(0xFFE4DFFF);
  static const Color primaryFixedDim = Color(0xFFC6BFFF);

  // Secondary — sunset accent (deals, urgency)
  static const Color secondary = Color(0xFFA83639);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFF7675);
  static const Color onSecondaryContainer = Color(0xFF720B16);

  // Tertiary — cyan (savings, success-adjacent)
  static const Color tertiary = Color(0xFF006461);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF007F7C);
  static const Color onTertiaryContainer = Color(0xFFD9FFFC);
  static const Color tertiaryAccent = Color(0xFF00CEC9);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Semantic aliases (used across features)
  static const Color paidGreen = Color(0xFF006461);
  static const Color pendingOrange = Color(0xFFFF7675);
  static const Color overdueRed = Color(0xFFBA1A1A);
  static const Color accentGold = Color(0xFFFF7675);

  // Legacy aliases — map old graphite/green tokens to FinTrack palette
  static const Color accentGreen = primaryContainer;
  static const Color accentBlue = tertiaryAccent;
  static const Color graphite = inverseSurface;
  static const Color graphiteLight = surfaceContainerLow;
  static const Color graphiteCard = surface;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = outline;

  static const Color onPrimaryFixedVariant = Color(0xFF4029BA);

  // Glass / depth
  static const Color glassWhite = Color(0xD9FFFFFF); // 85% white
  static const Color glassBorder = Color(0x1A5341CD); // primary 10%
  static const Color cardShadow = Color(0x0D5341CD); // primary 5%
}

class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double pill = 9999;
}

class AppSpacing {
  static const double unit = 4;
  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 32;
  static const double gutter = 16;
  static const double marginMobile = 24;
  static const double cardPadding = 20;
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
