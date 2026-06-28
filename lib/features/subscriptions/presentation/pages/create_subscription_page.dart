import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/constants/provider_icons.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/subscription_detector.dart';
import 'package:subsaver/core/utils/validators.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/subsavr_app_bar.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';
import 'package:subsaver/features/subscriptions/domain/entities/subscription_entity.dart';

class CreateSubscriptionPage extends StatefulWidget {
  const CreateSubscriptionPage({super.key});

  @override
  State<CreateSubscriptionPage> createState() => _CreateSubscriptionPageState();
}

class _CreateSubscriptionPageState extends State<CreateSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final Map<String, TextEditingController> _splitControllers = {};
  String _selectedProvider = 'Netflix';
  SubscriptionCategory _category = SubscriptionCategory.ott;
  BillingCycle _billingCycle = BillingCycle.monthly;
  DateTime _renewalDate = DateTime.now().add(const Duration(days: 30));
  String? _selectedGroupId;
  SplitType _splitType = SplitType.equal;

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _detectCategory() {
    final name = _nameController.text;
    if (name.isNotEmpty) {
      setState(() {
        _category = SubscriptionDetector.detectCategory(name);
        _selectedProvider = name;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final selectedGroup = _selectedGroup();
    final memberIds = selectedGroup?.members.map((m) => m.uid).toList() ?? [auth.user.id];
    final amount = double.parse(_costController.text);
    final percentages = _splitType == SplitType.percentage ? _parseSplits() : null;
    final customAmounts = _splitType == SplitType.custom ? _parseSplits() : null;

    if ((_splitType == SplitType.percentage || _splitType == SplitType.custom) &&
        (percentages ?? customAmounts ?? {}).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid split values for every member')),
      );
      return;
    }
    if (_splitType == SplitType.percentage && percentages != null) {
      final total = percentages.values.fold<double>(0, (sum, value) => sum + value);
      if ((total - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Percentage splits must total 100')),
        );
        return;
      }
    }
    if (_splitType == SplitType.custom && customAmounts != null) {
      final total = customAmounts.values.fold<double>(0, (sum, value) => sum + value);
      if ((total - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom splits must total the subscription cost')),
        );
        return;
      }
    }

    HapticFeedback.lightImpact();
    final subscription = SubscriptionEntity(
      id: '',
      name: _nameController.text,
      provider: _selectedProvider,
      category: _category,
      cost: amount,
      renewalDate: _renewalDate,
      billingCycle: _billingCycle,
      createdBy: auth.user.id,
      groupId: selectedGroup?.id,
      members: memberIds,
    );

    context.read<CreateSubscriptionBloc>().add(
          CreateSubscriptionSubmitted(
            subscription,
            groupId: selectedGroup?.id,
            splitType: selectedGroup == null ? null : _splitType,
            percentages: percentages,
            customAmounts: customAmounts,
          ),
        );
  }

  GroupEntity? _selectedGroup() {
    final dashboard = context.read<DashboardBloc>().state;
    if (dashboard is! DashboardLoaded || _selectedGroupId == null) return null;
    return dashboard.groups.where((g) => g.id == _selectedGroupId).firstOrNull;
  }

  Map<String, double> _parseSplits() {
    final group = _selectedGroup();
    if (group == null) return {};
    final values = <String, double>{};
    for (final member in group.members) {
      final value = double.tryParse(_splitControllers[member.uid]?.text.trim() ?? '');
      if (value == null || value < 0) return {};
      values[member.uid] = value;
    }
    return values;
  }

  void _syncSplitControllers(GroupEntity? group) {
    if (group == null) return;
    for (final member in group.members) {
      _splitControllers.putIfAbsent(member.uid, () => TextEditingController());
    }
  }

  Widget _buildSharingSection() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final groups = state is DashboardLoaded ? state.groups : <GroupEntity>[];
        final selectedGroup = groups.where((g) => g.id == _selectedGroupId).firstOrNull;
        _syncSplitControllers(selectedGroup);

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sharing', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedGroupId,
                decoration: const InputDecoration(labelText: 'Group'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Solo subscription')),
                  ...groups.map((g) => DropdownMenuItem<String?>(value: g.id, child: Text(g.name))),
                ],
                onChanged: (value) => setState(() {
                  _selectedGroupId = value;
                  _splitType = SplitType.equal;
                }),
              ),
              if (selectedGroup != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<SplitType>(
                  value: _splitType,
                  decoration: const InputDecoration(labelText: 'Split type'),
                  items: SplitType.values
                      .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                      .toList(),
                  onChanged: (value) => setState(() => _splitType = value ?? SplitType.equal),
                ),
                if (_splitType != SplitType.equal) ...[
                  const SizedBox(height: 12),
                  Text(
                    _splitType == SplitType.percentage
                        ? 'Percentages must total 100.'
                        : 'Amounts must total the subscription cost.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...selectedGroup.members.map((member) {
                    final label = member.name ?? member.uid.substring(0, 6);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: _splitControllers[member.uid],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: label,
                          suffixText: _splitType == SplitType.percentage ? '%' : '₹',
                        ),
                        validator: (_) {
                          if (_selectedGroupId == null || _splitType == SplitType.equal) return null;
                          final value = double.tryParse(_splitControllers[member.uid]?.text ?? '');
                          if (value == null || value < 0) return 'Enter a valid value';
                          return null;
                        },
                      ),
                    );
                  }),
                ],
              ] else if (groups.isEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Create a group first to split this subscription with friends.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubSavrAppBar(title: 'New Subscription', showBack: true),
      body: BlocListener<CreateSubscriptionBloc, CreateSubscriptionState>(
        listener: (context, state) {
          if (state is CreateSubscriptionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription created!')));
            context.pop();
          }
          if (state is CreateSubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Popular Services', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ProviderIcons.providerNames.length,
                    itemBuilder: (_, i) {
                      final name = ProviderIcons.providerNames[i];
                      final selected = _selectedProvider == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedProvider = name;
                              _nameController.text = name == 'Custom' ? '' : name;
                              if (name != 'Custom') _category = SubscriptionDetector.detectCategory(name);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 72,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.graphiteCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.accentGreen : AppColors.glassBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name[0], style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.accentGreen : AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(name.split(' ').first, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Subscription Name'),
                        onChanged: (_) => _detectCategory(),
                        validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Monthly Cost (₹)', prefixText: '₹ '),
                        validator: Validators.amount,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SubscriptionCategory>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: SubscriptionCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<BillingCycle>(
                        value: _billingCycle,
                        decoration: const InputDecoration(labelText: 'Billing Cycle'),
                        items: BillingCycle.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                        onChanged: (v) => setState(() => _billingCycle = v!),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Renewal Date'),
                        subtitle: Text('${_renewalDate.day}/${_renewalDate.month}/${_renewalDate.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(context: context, initialDate: _renewalDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
                          if (date != null) setState(() => _renewalDate = date);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSharingSection(),
                const SizedBox(height: 24),
                BlocBuilder<CreateSubscriptionBloc, CreateSubscriptionState>(
                  builder: (context, state) {
                    final isLoading = state is CreateSubscriptionLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Subscription'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
