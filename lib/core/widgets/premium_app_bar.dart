import 'package:flutter/material.dart';
import 'package:subsaver/core/theme/app_theme.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(title),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
      flexibleSpace: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.inverseSurface.withValues(alpha: 0.85)
                : AppColors.glassWhite,
          ),
        ),
      ),
    );
  }
}
