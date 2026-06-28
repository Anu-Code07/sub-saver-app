import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/utils/gmail_subscription_parser.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/premium_app_bar.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

class GmailImportPage extends StatefulWidget {
  const GmailImportPage({super.key});

  @override
  State<GmailImportPage> createState() => _GmailImportPageState();
}

class _GmailImportPageState extends State<GmailImportPage> {
  final _pasteController = TextEditingController();
  List<GmailSubscriptionCandidate> _candidates = [];
  final _selected = <int>{};

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;
    final blocks = text.split(RegExp(r'\n{2,}'));
    setState(() {
      _candidates = GmailSubscriptionParser.parseMessages(blocks);
      _selected.clear();
      for (var i = 0; i < _candidates.length; i++) {
        _selected.add(i);
      }
    });
  }

  void _importSelected() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    for (final i in _selected) {
      final c = _candidates[i];
      final sub = SubscriptionEntity(
        id: '',
        name: c.name,
        provider: c.provider,
        category: c.category,
        cost: c.amount ?? 0,
        renewalDate: c.renewalDate ?? DateTime.now().add(const Duration(days: 30)),
        billingCycle: BillingCycle.monthly,
        createdBy: auth.user.id,
        members: [auth.user.id],
      );
      context.read<CreateSubscriptionBloc>().add(CreateSubscriptionSubmitted(sub));
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Importing ${_selected.length} subscriptions...')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Import Subscriptions', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Paste receipt emails or notification text. We detect Netflix, Prime, Spotify, and more.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GlassCard(
            child: TextField(
              controller: _pasteController,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Paste email content here...', border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _parse, child: const Text('Scan text')),
          if (_candidates.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Found ${_candidates.length} subscriptions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(_candidates.length, (i) {
              final c = _candidates[i];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() => v == true ? _selected.add(i) : _selected.remove(i)),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.category.label}${c.amount != null ? ' · ${CurrencyFormatter.format(c.amount!)}' : ''}'),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _selected.isEmpty ? null : _importSelected, child: Text('Import ${_selected.length} selected')),
          ],
        ],
      ),
    );
  }
}
