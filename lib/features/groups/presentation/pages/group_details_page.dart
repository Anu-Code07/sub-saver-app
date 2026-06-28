import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/premium_app_bar.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/settlements/presentation/pages/payment_proof_page.dart';
import 'package:subsaver/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:subsaver/injection_container.dart';

class GroupDetailsPage extends StatefulWidget {
  const GroupDetailsPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Load group via stream - simplified with GroupBloc when group entity is available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Group',
        showBack: true,
      ),
      body: StreamBuilder<List<GroupEntity>>(
        stream: sl<GroupRepository>().watchGroups(
          (context.read<AuthBloc>().state as AuthAuthenticated).user.id,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final group = snapshot.data!.where((g) => g.id == widget.groupId).firstOrNull;
          if (group == null) return const Center(child: Text('Group not found'));
          final currentUserId = (context.read<AuthBloc>().state as AuthAuthenticated).user.id;
          final isOwner = group.ownerId == currentUserId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Invite Code: ${group.inviteCode}', style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Text('Wallet: ₹${group.walletBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareInvite(group),
                            icon: const Icon(Icons.ios_share_outlined, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showQr(context, group.inviteCode),
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('QR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: () => context.push('/groups/${group.id}/settle'), child: const Text('Settle Up'))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(onPressed: () => context.push('/groups/${group.id}/wallet'), child: const Text('Wallet'))),
                ],
              ),
              const SizedBox(height: 24),
              Text('Members (${group.members.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...group.members.map((m) => GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text((m.name ?? 'U')[0])),
                      title: Text(m.name ?? m.uid.substring(0, 8)),
                      subtitle: Text(m.uid, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isOwner && m.uid != currentUserId
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_outlined, color: AppColors.overdueRed),
                              onPressed: () => context
                                  .read<GroupBloc>()
                                  .add(GroupRemoveMemberRequested(group.id, m.uid)),
                            )
                          : Chip(label: Text(m.role.label, style: const TextStyle(fontSize: 11))),
                    ),
                  )),
              const SizedBox(height: 24),
              Text('Shared Expenses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StreamBuilder<List<ExpenseEntity>>(
                stream: sl<ExpenseRepository>().watchExpenses(group.id),
                builder: (context, expenseSnap) {
                  final expenses = expenseSnap.data ?? [];
                  if (!expenseSnap.hasData) {
                    return const GlassCard(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
                  }
                  if (expenses.isEmpty) {
                    return const GlassCard(child: Padding(padding: EdgeInsets.all(16), child: Text('No shared expenses yet')));
                  }
                  return Column(
                    children: expenses.map((expense) {
                      final split = expense.splits.where((s) => s.uid == currentUserId).firstOrNull;
                      final canUploadProof = split != null && split.status != PaymentStatus.paid;
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
                          title: Text(expense.subscriptionName ?? 'Shared expense'),
                          subtitle: Text('Your share: ${split == null ? '-' : CurrencyFormatter.format(split.amount)}'),
                          trailing: canUploadProof
                              ? TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentProofPage(
                                        groupId: group.id,
                                        expenseId: expense.id,
                                        subscriptionId: expense.subscriptionId,
                                        userId: currentUserId,
                                        expectedAmount: split.amount,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Proof'),
                                )
                              : const Chip(label: Text('Paid')),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StreamBuilder<List<ActivityEntity>>(
                stream: sl<GroupRepository>().watchActivity(group.id),
                builder: (context, actSnap) {
                  if (!actSnap.hasData || actSnap.data!.isEmpty) {
                    return const GlassCard(child: Padding(padding: EdgeInsets.all(16), child: Text('No activity yet')));
                  }
                  return Column(
                    children: actSnap.data!.map((a) => GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: const Icon(Icons.history, color: AppColors.textSecondary, size: 20),
                            title: Text(a.message, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(a.actorName, style: const TextStyle(fontSize: 12)),
                          ),
                        )).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareInvite(GroupEntity group) async {
    final message = 'Join my ${group.name} group on SubSavr with invite code ${group.inviteCode}';
    await Clipboard.setData(ClipboardData(text: group.inviteCode));
    await SharePlus.instance.share(ShareParams(text: message));
  }

  void _showQr(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan to Join'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: QrImageView(data: inviteCode, size: 200),
        ),
      ),
    );
  }
}
