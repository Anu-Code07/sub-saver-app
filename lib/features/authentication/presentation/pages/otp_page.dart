import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subsaver/core/config/app_config.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/validators.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.verificationId, required this.phoneNumber});

  final String verificationId;
  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop())),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) context.go('/home');
            if (state is AuthError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verify OTP', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Enter the 6-digit code sent to +91 ${widget.phoneNumber}', style: TextStyle(color: AppColors.textSecondary)),
                  if (AppConfig.useMockAuth) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        'Mock OTP: ${AppConstants.mockOtpCode}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  GlassCard(
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      decoration: const InputDecoration(hintText: '• • • • • •'),
                      validator: Validators.otp,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    HapticFeedback.lightImpact();
                                    context.read<AuthBloc>().add(AuthOtpSubmitted(widget.verificationId, _otpController.text));
                                  }
                                },
                          child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
