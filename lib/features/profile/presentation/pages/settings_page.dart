import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/injection_container.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final mode = state is ThemeLoaded ? state.mode : AppThemeMode.light;
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SegmentedButton<AppThemeMode>(
                      segments: const [
                        ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                        ButtonSegment(value: AppThemeMode.system, label: Text('System')),
                      ],
                      selected: {mode},
                      onSelectionChanged: (value) => context.read<ThemeCubit>().setMode(value.first),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const _BiometricSettingsTile(),
          const SizedBox(height: 8),
          _SettingsTile(icon: Icons.currency_rupee, title: 'Currency', subtitle: AppConstants.defaultCurrency, onTap: () {}),
          _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Manage alerts', onTap: () => context.push('/notifications')),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy', subtitle: 'Control your data', onTap: () => _showInfo(context, 'Privacy', 'SubSavr stores profile, group, subscription, wallet, and payment proof data in Firebase. Production builds should link the published privacy policy here.')),
          _SettingsTile(icon: Icons.download_outlined, title: 'Export Data', subtitle: 'Download your data', onTap: () => _showInfo(context, 'Export Data', 'Export requires a Firebase callable function to package your account data securely. This screen is ready for that backend hook.')),
          _SettingsTile(icon: Icons.delete_outline, title: 'Delete Account', subtitle: 'Permanently delete', onTap: () => _confirmDelete(context), isDestructive: true),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('Production deletion needs a backend function that deletes Firebase Auth, Firestore, Storage, and FCM data. For now this signs you out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out', style: TextStyle(color: AppColors.overdueRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
      context.go('/login');
    }
  }
}

class _BiometricSettingsTile extends StatefulWidget {
  const _BiometricSettingsTile();

  @override
  State<_BiometricSettingsTile> createState() => _BiometricSettingsTileState();
}

class _BiometricSettingsTileState extends State<_BiometricSettingsTile> {
  late final AuthRepository _authRepository = sl<AuthRepository>();
  bool _enabled = false;
  bool _available = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _authRepository.isBiometricEnabled();
    final available = await _authRepository.canUseBiometrics();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _available = available;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (!_available) return;
    if (value) {
      try {
        await _authRepository.unlockWithBiometric();
        await _authRepository.setBiometricEnabled(true);
        if (mounted) setState(() => _enabled = true);
      } catch (_) {
        if (mounted) setState(() => _enabled = false);
      }
      return;
    }
    await _authRepository.setBiometricEnabled(false);
    if (mounted) setState(() => _enabled = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GlassCard(
        child: ListTile(
          leading: Icon(Icons.face_outlined),
          title: Text('Face / fingerprint lock'),
          trailing: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return GlassCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.face_outlined, color: AppColors.textSecondary),
        title: const Text('Face / fingerprint lock'),
        subtitle: Text(
          _available
              ? 'Skip OTP on return — unlock with biometrics'
              : 'Not available on this device',
          style: const TextStyle(fontSize: 12),
        ),
        value: _enabled && _available,
        onChanged: _available ? _toggle : null,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.isDestructive = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: isDestructive ? AppColors.overdueRed : AppColors.textSecondary),
        title: Text(title, style: TextStyle(color: isDestructive ? AppColors.overdueRed : null)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }
}
