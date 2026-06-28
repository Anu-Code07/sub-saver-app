import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:subsaver/core/services/ocr_service.dart';
import 'package:subsaver/core/theme/app_theme.dart';
import 'package:subsaver/core/utils/formatters.dart';
import 'package:subsaver/core/utils/payment_receipt_parser.dart';
import 'package:subsaver/core/widgets/glass_card.dart';
import 'package:subsaver/core/widgets/premium_app_bar.dart';
import 'package:subsaver/features/settlements/domain/repositories/payment_proof_repository.dart';
import 'package:subsaver/injection_container.dart';

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
  String? _imagePath;
  String? _ocrText;
  double? _parsedAmount;
  String? _referenceId;
  bool _uploading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;
    }
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _imagePath = file.path);

    final ocr = sl<OcrService>();
    final text = await ocr.recognizeFromFile(file.path);
    final parsed = PaymentReceiptParser.parse(text);
    setState(() {
      _ocrText = text;
      _parsedAmount = parsed.amount;
      _referenceId = parsed.referenceId;
    });
  }

  Future<void> _upload() async {
    if (_imagePath == null) return;
    setState(() => _uploading = true);
    try {
      await sl<PaymentProofRepository>().uploadProof(
        groupId: widget.groupId,
        expenseId: widget.expenseId,
        subscriptionId: widget.subscriptionId,
        uploadedBy: widget.userId,
        localImagePath: _imagePath!,
        ocrText: _ocrText,
        amount: _parsedAmount,
        referenceId: _referenceId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment proof uploaded for review')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountMatch = widget.expectedAmount != null &&
        _parsedAmount != null &&
        (_parsedAmount! - widget.expectedAmount!).abs() < 1;

    return Scaffold(
      appBar: const PremiumAppBar(title: 'Upload Payment Proof', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Take a screenshot of your UPI/bank payment', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(_imagePath!), fit: BoxFit.cover, height: 200, width: double.infinity),
              ),
            ),
          ],
          if (_parsedAmount != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(amountMatch ? Icons.check_circle : Icons.warning_amber, color: amountMatch ? AppColors.paidGreen : AppColors.pendingOrange),
                      const SizedBox(width: 8),
                      Text('Detected: ${CurrencyFormatter.format(_parsedAmount!)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_referenceId != null) Text('Ref: $_referenceId', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _imagePath == null || _uploading ? null : _upload,
            child: _uploading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit for review'),
          ),
        ],
      ),
    );
  }
}
