import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/subsavr_app_bar.dart';
import 'package:subsaver/core/widgets/shimmer_loading.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';

class SubscriptionListPage extends StatefulWidget {
  const SubscriptionListPage({super.key});

  @override
  State<SubscriptionListPage> createState() => _SubscriptionListPageState();
}

class _SubscriptionListPageState extends State<SubscriptionListPage> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<SubscriptionListBloc>().add(SubscriptionListWatchRequested(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubSavrAppBar(
        title: 'Subscriptions',
        showBack: true,
        actions: [
          IconButton(icon: const Icon(Icons.file_upload_outlined), onPressed: () => context.push('/subscriptions/import')),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/subscriptions/create')),
        ],
      ),
      body: BlocBuilder<SubscriptionListBloc, SubscriptionListState>(
        builder: (context, state) {
          if (state is SubscriptionListLoading) {
            return ListView(padding: const EdgeInsets.all(16), children: List.generate(5, (_) => const ShimmerListTile()));
          }
          if (state is SubscriptionListError) return Center(child: Text(state.message));
          if (state is SubscriptionListLoaded) {
            if (state.subscriptions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.subscriptions_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('No subscriptions yet'),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => context.push('/subscriptions/create'), child: const Text('Add Subscription')),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.subscriptions.length,
              itemBuilder: (context, index) {
                final sub = state.subscriptions[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + index * 50),
                  builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
                  child: GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => context.push('/subscriptions/${sub.id}'),
                    child: Hero(
                      tag: 'sub_${sub.id}',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
                          child: Text(sub.provider.isNotEmpty ? sub.provider[0].toUpperCase() : '?'),
                        ),
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${sub.category.label} · ${sub.billingCycle.label}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(CurrencyFormatter.format(sub.cost), style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (sub.isRenewingSoon)
                              const Text('Renewing soon', style: TextStyle(color: AppColors.pendingOrange, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
