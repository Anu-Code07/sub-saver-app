import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

export 'package:subsaver/core/theme/app_colors.dart';
import 'package:subsaver/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.inverseSurface : AppColors.background,
      colorScheme: colorScheme,
    );

    final headlineFont = GoogleFonts.lexend;
    final bodyFont = GoogleFonts.lexend;

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, headlineFont, bodyFont, isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: headlineFont(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceContainerHigh : AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceContainer : AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: bodyFont(color: AppColors.outline, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          textStyle: bodyFont(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          textStyle: bodyFont(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.inverseSurface.withValues(alpha: 0.92)
            : AppColors.glassWhite,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return bodyFont(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.outline,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.outline,
            size: 24,
          );
        }),
        elevation: 0,
        height: 72,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.onSurface.withValues(alpha: 0.05),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: bodyFont(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceContainerHigh : AppColors.inverseSurface,
        contentTextStyle: bodyFont(color: AppColors.inverseOnSurface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.cardShadow,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.inversePrimary,
    onPrimary: AppColors.onPrimaryFixedVariant,
    primaryContainer: AppColors.primary,
    onPrimaryContainer: AppColors.primaryFixed,
    secondary: AppColors.secondaryContainer,
    onSecondary: AppColors.onSecondaryContainer,
    secondaryContainer: AppColors.secondary,
    onSecondaryContainer: AppColors.onSecondary,
    tertiary: AppColors.tertiaryAccent,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiary,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.errorContainer,
    onError: AppColors.onErrorContainer,
    errorContainer: AppColors.error,
    onErrorContainer: AppColors.onError,
    surface: AppColors.inverseSurface,
    onSurface: AppColors.inverseOnSurface,
    onSurfaceVariant: AppColors.outlineVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: Colors.black26,
    inverseSurface: AppColors.surface,
    onInverseSurface: AppColors.onSurface,
    inversePrimary: AppColors.primary,
  );

  static TextTheme _textTheme(
    TextTheme base,
    TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      double? letterSpacing,
    }) headlineFont,
    TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      double? letterSpacing,
    }) bodyFont,
    bool isDark,
  ) {
    final textColor = isDark ? AppColors.inverseOnSurface : AppColors.onSurface;
    final muted = isDark ? AppColors.outlineVariant : AppColors.onSurfaceVariant;

    return TextTheme(
      displayLarge: headlineFont(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 48 / 40,
        letterSpacing: -0.8,
        color: textColor,
      ),
      headlineLarge: headlineFont(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.28,
        color: textColor,
      ),
      headlineMedium: headlineFont(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: textColor,
      ),
      titleLarge: headlineFont(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
      titleMedium: bodyFont(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: bodyFont(fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18, color: textColor),
      bodyMedium: bodyFont(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: textColor),
      bodySmall: bodyFont(fontSize: 14, fontWeight: FontWeight.w400, color: muted),
      labelLarge: bodyFont(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.28, color: textColor),
      labelMedium: bodyFont(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.48, color: muted),
      labelSmall: bodyFont(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.44, color: muted),
    );
  }
}
