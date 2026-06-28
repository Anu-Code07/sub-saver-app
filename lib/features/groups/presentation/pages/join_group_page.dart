import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/subsavr_app_bar.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:subsaver/features/dashboard/presentation/bloc/dashboard_state.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _codeController = TextEditingController();
  bool _scanning = true;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _join(String code) {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final trimmed = code.trim().toUpperCase();
    if (trimmed.length < 4) return;
    context.read<GroupBloc>().add(GroupJoinRequested(trimmed, auth.user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubSavrAppBar(title: 'Join Group', showBack: true),
      body: BlocListener<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group!')));
            context.go('/groups/${state.group.id}');
          }
          if (state is GroupError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Scan invite QR', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  child: _scanning
                      ? MobileScanner(
                          onDetect: (capture) {
                            final code = capture.barcodes.firstOrNull?.rawValue;
                            if (code != null && code.isNotEmpty) {
                              setState(() => _scanning = false);
                              _codeController.text = code;
                              _join(code);
                            }
                          },
                        )
                      : Center(
                          child: TextButton(
                            onPressed: () => setState(() => _scanning = true),
                            child: const Text('Scan again'),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Or enter invite code', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassCard(
              child: TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'ABCD1234',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _join(_codeController.text),
              child: const Text('Join Group'),
            ),
          ],
        ),
      ),
    );
  }
}
