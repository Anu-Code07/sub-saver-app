import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/widgets/glass_card.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SubSavr Plus'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 48, color: AppColors.accentGold),
                const SizedBox(height: 16),
                Text(
                  'SubSavr Plus',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Unlock premium features', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                const Text(
                  '₹199/month',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.accentGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...['Unlimited Groups', 'Advanced Analytics', 'AI Insights', 'Export Reports', 'Custom Themes'].map(
            (f) => GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.check_circle, color: AppColors.accentGreen),
                title: Text(f),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('In-app purchases coming soon')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.graphite,
              ),
              child: const Text('Upgrade to Plus'),
            ),
          ),
        ],
      ),
    );
  }
}
