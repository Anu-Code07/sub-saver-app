import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/services/reminder_service.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:subsaver/injection_container.dart';

class SubscriptionDetailPage extends StatefulWidget {
  const SubscriptionDetailPage({super.key, required this.id});

  final String id;

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionDetailBloc>().add(SubscriptionDetailLoadRequested(widget.id));
  }

  String? get _userId {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
  }

  Future<void> _confirmAction(String title, String body, VoidCallback action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) action();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionDetailBloc, SubscriptionDetailState>(
      listener: (context, state) {
        if (state is SubscriptionDetailActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          if (state.popRoute) context.pop();
        }
        if (state is SubscriptionDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final title = state is SubscriptionDetailLoaded ? state.subscription.provider : 'Subscription';
        final isActive = state is SubscriptionDetailLoaded && state.subscription.status == 'active';
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _CircleButton(
                icon: LucideIcons.arrowLeft,
                onTap: () => context.pop(),
              ),
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            actions: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _CircleButton(
                    icon: LucideIcons.pencil,
                    onTap: () => _showMenuSheet(state.subscription),
                  ),
                ),
            ],
          ),
          body: switch (state) {
            SubscriptionDetailLoading() => const Center(child: CircularProgressIndicator()),
            SubscriptionDetailError(:final message) => Center(child: Text(message)),
            SubscriptionDetailLoaded(:final subscription) => _Body(subscription: subscription, userId: _userId),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Future<void> _showMenuSheet(SubscriptionEntity sub) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Edit subscription'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.ban),
              title: const Text('Cancel subscription'),
              onTap: () => Navigator.pop(ctx, 'cancel'),
            ),
            if (sub.members.length > 1)
              ListTile(
                leading: const Icon(LucideIcons.logOut),
                title: const Text('Leave subscription'),
                onTap: () => Navigator.pop(ctx, 'leave'),
              ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.overdueRed),
              title: const Text('Delete', style: TextStyle(color: AppColors.overdueRed)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action != null) _onMenu(action, sub);
  }

  void _onMenu(String value, SubscriptionEntity sub) {
    final uid = _userId;
    if (uid == null) return;
    final bloc = context.read<SubscriptionDetailBloc>();
    switch (value) {
      case 'edit':
        _showEditSheet(sub);
      case 'cancel':
        _confirmAction('Cancel subscription?', 'This marks the subscription as cancelled.', () {
          bloc.add(SubscriptionDetailCancelRequested(sub.id));
        });
      case 'leave':
        _confirmAction('Leave subscription?', 'You will no longer share this subscription.', () {
          bloc.add(SubscriptionDetailLeaveRequested(sub.id, uid));
        });
      case 'delete':
        _confirmAction('Delete subscription?', 'This cannot be undone.', () {
          bloc.add(SubscriptionDetailDeleteRequested(sub.id));
        });
    }
  }

  Future<void> _showEditSheet(SubscriptionEntity sub) async {
    final nameCtrl = TextEditingController(text: sub.name);
    final costCtrl = TextEditingController(text: sub.cost.toStringAsFixed(0));
    final updated = await showModalBottomSheet<SubscriptionEntity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final cost = double.tryParse(costCtrl.text);
                if (cost == null) return;
                Navigator.pop(ctx, sub.copyWith(name: nameCtrl.text.trim(), cost: cost));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (updated != null) {
      if (!mounted) return;
      context.read<SubscriptionDetailBloc>().add(SubscriptionDetailUpdateRequested(updated));
    }
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.subscription, required this.userId});

  final SubscriptionEntity subscription;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final isOwner = userId == subscription.createdBy;
    final isShared = subscription.members.length > 1;
    final sharePerMember = subscription.members.isEmpty
        ? subscription.cost
        : subscription.cost / subscription.members.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _Hero(subscription: subscription),
        const SizedBox(height: 24),
        _ActionGrid(subscription: subscription, onReminder: () => _sendReminder(context)),
        const SizedBox(height: 28),
        Text('Subscription Info',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  icon: LucideIcons.calendar,
                  iconColor: AppColors.primary,
                  label: 'Next billing',
                  value: DateFormatter.formatDate(subscription.renewalDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BentoCard(
                  icon: LucideIcons.pieChart,
                  iconColor: AppColors.secondary,
                  label: 'Monthly cost',
                  value: CurrencyFormatter.format(subscription.monthlyCost),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _WideBentoCard(
          label: 'Current plan',
          value: '${subscription.category.label} · ${subscription.billingCycle.label}',
        ),
        if (isShared) ...[
          const SizedBox(height: 16),
          _WideBentoCard(
            label: 'Your share',
            value: CurrencyFormatter.format(sharePerMember),
            valueColor: AppColors.tertiary,
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text('Members (${subscription.members.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Icon(LucideIcons.usersRound, size: 18, color: AppColors.outline),
          ],
        ),
        const SizedBox(height: 12),
        ...subscription.members.map((m) => _MemberRow(
              memberId: m,
              isOwnerEntry: m == subscription.createdBy,
              canRemove: isOwner && m != subscription.createdBy && m != userId,
              onRemove: () => context
                  .read<SubscriptionDetailBloc>()
                  .add(SubscriptionDetailRemoveMemberRequested(subscription.id, m)),
            )),
      ],
    );
  }

  Future<void> _sendReminder(BuildContext context) async {
    final message = await sl<ReminderService>().generateReminder(
      subscriptionName: subscription.name,
      amount: subscription.cost / (subscription.members.isEmpty ? 1 : subscription.members.length),
      tone: AiTone.funny,
      memberName: 'friend',
    );
    await SharePlus.instance.share(ShareParams(text: message));
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.subscription});

  final SubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final gradient = _ProviderTheme.gradientFor(subscription.provider);
    final initial =
        subscription.provider.isNotEmpty ? subscription.provider[0].toUpperCase() : '?';

    return Hero(
      tag: 'sub_${subscription.id}',
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 18),
                Text(subscription.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: CurrencyFormatter.format(subscription.cost),
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                        text: '/${subscription.billingCycle.label.toLowerCase().substring(0, 2)}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subscription.isRenewingSoon)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Renews soon',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.subscription, required this.onReminder});

  final SubscriptionEntity subscription;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onReminder,
            icon: const Icon(LucideIcons.bellRing, size: 18),
            label: const Text('Remind'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context
                .read<SubscriptionDetailBloc>()
                .add(SubscriptionDetailLoadRequested(subscription.id)),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WideBentoCard extends StatelessWidget {
  const _WideBentoCard({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: AppColors.outline, size: 20),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.memberId,
    required this.isOwnerEntry,
    required this.canRemove,
    required this.onRemove,
  });

  final String memberId;
  final bool isOwnerEntry;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(memberId.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberId.length > 12 ? '${memberId.substring(0, 12)}…' : memberId,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(isOwnerEntry ? 'Owner' : 'Member',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(LucideIcons.userMinus, color: AppColors.overdueRed, size: 20),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _ProviderTheme {
  static const _map = <String, List<Color>>{
    'netflix': [Color(0xFFE50914), Color(0xFF000000)],
    'spotify': [Color(0xFF1DB954), Color(0xFF0A3D1E)],
    'prime': [Color(0xFF00A8E1), Color(0xFF0A2540)],
    'disney': [Color(0xFF113CCF), Color(0xFF0A1F4D)],
    'hotstar': [Color(0xFF1F80E0), Color(0xFF0A1A3D)],
    'youtube': [Color(0xFFFF0000), Color(0xFF1A0000)],
    'apple': [Color(0xFF333333), Color(0xFF000000)],
    'jio': [Color(0xFF0A2885), Color(0xFF071A52)],
    'chatgpt': [Color(0xFF10A37F), Color(0xFF0A3D2E)],
  };

  static LinearGradient gradientFor(String provider) {
    final key = provider.toLowerCase();
    final match = _map.entries.firstWhere(
      (e) => key.contains(e.key),
      orElse: () => const MapEntry('', [AppColors.primary, AppColors.primaryContainer]),
    );
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: match.value,
    );
  }
}
