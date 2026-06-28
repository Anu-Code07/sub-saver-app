import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/balance_display.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/subsavr_app_bar.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletLoadRequested(widget.groupId));
  }

  void _addMoney() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Money'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                final auth = context.read<AuthBloc>().state;
                if (auth is AuthAuthenticated) {
                  HapticFeedback.lightImpact();
                  context.read<WalletBloc>().add(WalletAddMoney(groupId: widget.groupId, amount: amount, userId: auth.user.id));
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubSavrAppBar(title: 'Shared Wallet', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMoney,
        label: const Text('Add Money'),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) return const Center(child: CircularProgressIndicator());
          if (state is WalletError) return Center(child: Text(state.message));
          if (state is WalletLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: BalanceDisplay(amount: state.balance, label: 'Group Balance'),
                ),
                const SizedBox(height: 24),
                Text('Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (state.transactions.isEmpty)
                  const GlassCard(child: Padding(padding: EdgeInsets.all(16), child: Text('No transactions yet')))
                else
                  ...state.transactions.map((tx) => GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            tx.type == 'add' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.type == 'add' ? AppColors.paidGreen : AppColors.pendingOrange,
                          ),
                          title: Text(tx.type == 'add' ? 'Added' : 'Withdrawn'),
                          subtitle: Text(DateFormatter.formatDate(tx.timestamp)),
                          trailing: Text(
                            '${tx.type == 'add' ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: tx.type == 'add' ? AppColors.paidGreen : AppColors.pendingOrange,
                            ),
                          ),
                        ),
                      )),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
