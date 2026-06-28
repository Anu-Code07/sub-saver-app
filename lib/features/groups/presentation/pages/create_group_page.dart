import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/premium_app_bar.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:subsaver/core/constants/subscription_categories.dart';
import 'package:subsaver/features/groups/domain/entities/group_entity.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final group = GroupEntity(
      id: '',
      name: name,
      ownerId: auth.user.id,
      inviteCode: '',
      members: [
        GroupMemberEntity(uid: auth.user.id, role: GroupRole.owner, joinedAt: DateTime.now(), name: auth.user.name),
      ],
    );
    context.read<GroupBloc>().add(GroupCreateRequested(group));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Create Group', showBack: true),
      body: BlocListener<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupCreated) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created!')));
            context.go('/groups/${state.group.id}');
          }
          if (state is GroupError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Group name', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GlassCard(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Roommates, Family...', border: InputBorder.none),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _create, child: const Text('Create Group')),
            ],
          ),
        ),
      ),
    );
  }
}
