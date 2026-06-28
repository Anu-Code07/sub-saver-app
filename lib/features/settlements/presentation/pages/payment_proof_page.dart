import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/subsavr_app_bar.dart';
import 'package:subsaver/features/settlements/presentation/bloc/payment_proof_bloc.dart';

class PaymentProofPage extends StatefulWidget {
  const PaymentProofPage({
    super.key,
    required this.groupId,
    required this.expenseId,
    required this.subscriptionId,
    required this.userId,
    this.expectedAmount,
  });

  final String groupId;
  final String expenseId;
  final String subscriptionId;
  final String userId;
  final double? expectedAmount;

  @override
  State<PaymentProofPage> createState() => _PaymentProofPageState();
}

class _PaymentProofPageState extends State<PaymentProofPage> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentProofBloc>().add(const PaymentProofResetRequested());
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    if (!mounted) return;
    context.read<PaymentProofBloc>().add(PaymentProofImageSelected(file.path));
  }

  void _upload() {
    context.read<PaymentProofBloc>().add(PaymentProofSubmitRequested(
          groupId: widget.groupId,
          expenseId: widget.expenseId,
          subscriptionId: widget.subscriptionId,
          uploadedBy: widget.userId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubSavrAppBar(title: 'Upload Payment Proof', showBack: true),
      body: BlocConsumer<PaymentProofBloc, PaymentProofState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment proof uploaded for review')),
            );
            Navigator.pop(context, true);
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final amountMatch = widget.expectedAmount != null &&
              state.parsedAmount != null &&
              (state.parsedAmount! - widget.expectedAmount!).abs() < 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Take a screenshot of your UPI/bank payment',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isScanning || state.isUploading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isScanning || state.isUploading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (state.localImagePath != null) ...[
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(state.localImagePath!),
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
              if (state.isScanning) ...[
                const SizedBox(height: 16),
                const GlassCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Scanning receipt with OCR...'),
                    ],
                  ),
                ),
              ],
              if (state.parsedAmount != null) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            amountMatch ? Icons.check_circle : Icons.warning_amber,
                            color: amountMatch
                                ? AppColors.paidGreen
                                : AppColors.pendingOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detected: ${CurrencyFormatter.format(state.parsedAmount!)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (state.referenceId != null)
                        Text(
                          'Ref: ${state.referenceId}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.localImagePath == null || state.isUploading
                    ? null
                    : _upload,
                child: state.isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit for review'),
              ),
            ],
          );
        },
      ),
    );
  }
}
