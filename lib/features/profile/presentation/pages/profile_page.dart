import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_event.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings'))],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          UserEntity? user;
          if (state is ProfileLoaded) user = state.user;
          if (state is ProfileUpdated) user = state.user;
          if (user == null) {
            final auth = context.read<AuthBloc>().state;
            if (auth is AuthAuthenticated) user = auth.user;
          }
          if (user == null) return const Center(child: CircularProgressIndicator());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
                      backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                      child: user.avatar == null ? Text((user.name.isEmpty ? 'U' : user.name[0]).toUpperCase(), style: const TextStyle(fontSize: 32)) : null,
                    ),
                    TextButton.icon(
                      onPressed: () => _pickAvatar(user!),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Change photo'),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (user.email != null) Text(user.email!, style: const TextStyle(color: AppColors.textSecondary)),
                    if (user.isPremium)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Chip(label: Text('SubSavr Plus'), backgroundColor: AppColors.accentGold),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileTile(icon: Icons.phone, label: 'Phone', value: user.phone ?? 'Not set'),
              _ProfileTile(icon: Icons.account_balance_wallet, label: 'UPI ID', value: user.upiId ?? 'Not set'),
              _ProfileTile(icon: Icons.payment, label: 'Payment Method', value: user.preferredPaymentMethod ?? 'Not set'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _editProfile(context, user!),
                  child: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.overdueRed, side: const BorderSide(color: AppColors.overdueRed)),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editProfile(BuildContext context, UserEntity user) {
    final nameController = TextEditingController(text: user.name);
    final upiController = TextEditingController(text: user.upiId ?? '');
    final methodController = TextEditingController(text: user.preferredPaymentMethod ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: upiController, decoration: const InputDecoration(labelText: 'UPI ID')),
            TextField(controller: methodController, decoration: const InputDecoration(labelText: 'Preferred payment method')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(ProfileUpdateRequested(user.copyWith(
                    name: nameController.text.trim(),
                    upiId: upiController.text.trim().isEmpty ? null : upiController.text.trim(),
                    preferredPaymentMethod: methodController.text.trim().isEmpty ? null : methodController.text.trim(),
                  )));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(UserEntity user) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    if (!mounted) return;
    context.read<ProfileBloc>().add(ProfileAvatarUploadRequested(user.id, image.path));
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)), Text(value)])),
        ],
      ),
    );
  }
}
