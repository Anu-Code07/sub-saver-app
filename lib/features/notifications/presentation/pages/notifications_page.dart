import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/shimmer_loading.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<NotificationBloc>().add(NotificationWatchRequested(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return ListView(padding: const EdgeInsets.all(16), children: List.generate(5, (_) => const ShimmerListTile()));
          }
          if (state is NotificationError) return Center(child: Text(state.message));
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.notifications_none, size: 64, color: AppColors.textMuted), SizedBox(height: 16), Text('No notifications')]));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              itemBuilder: (_, i) {
                final n = state.notifications[i];
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Icon(_iconForCategory(n.category), color: n.read ? AppColors.textMuted : AppColors.accentGreen),
                    title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.w600)),
                    subtitle: Text(n.body),
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

  IconData _iconForCategory(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.dueReminder => Icons.payment,
      NotificationCategory.renewalReminder => Icons.event_repeat,
      NotificationCategory.groupActivity => Icons.group,
      NotificationCategory.paymentReceived => Icons.check_circle,
    };
  }
}
