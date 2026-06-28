import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/premium_app_bar.dart';
import 'package:subsaver/core/widgets/shimmer_loading.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettlementBloc>().add(SettlementLoadRequested(widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Settle Up', showBack: true),
      body: BlocBuilder<SettlementBloc, SettlementState>(
        builder: (context, state) {
          if (state is SettlementLoading) {
            return ListView(padding: const EdgeInsets.all(16), children: List.generate(3, (_) => const ShimmerListTile()));
          }
          if (state is SettlementError) return Center(child: Text(state.message));
          if (state is SettlementLoaded) {
            if (state.settlements.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.paidGreen),
                    SizedBox(height: 16),
                    Text('All settled up!'),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Optimized payments', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...state.settlements.map((s) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: const CircleAvatar(backgroundColor: AppColors.accentGreen, child: Icon(Icons.arrow_forward, color: AppColors.graphite, size: 18)),
                        title: Text('${s.fromUserName ?? s.fromUserId.substring(0, 6)} pays ${s.toUserName ?? s.toUserId.substring(0, 6)}'),
                        subtitle: const Text('Optimized debt'),
                        trailing: Text(CurrencyFormatter.format(s.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
