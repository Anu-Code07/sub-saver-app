import 'package:equatable/equatable.dart';

enum PaymentProofStatus { pending, verified, rejected }

class PaymentProofEntity extends Equatable {
  const PaymentProofEntity({
    required this.id,
    required this.groupId,
    required this.expenseId,
    required this.subscriptionId,
    required this.uploadedBy,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    this.amount,
    this.referenceId,
    this.ocrText,
    this.reviewedBy,
    this.reviewNote,
  });

  final String id;
  final String groupId;
  final String expenseId;
  final String subscriptionId;
  final String uploadedBy;
  final String imageUrl;
  final PaymentProofStatus status;
  final DateTime createdAt;
  final double? amount;
  final String? referenceId;
  final String? ocrText;
  final String? reviewedBy;
  final String? reviewNote;

  @override
  List<Object?> get props => [
        id, groupId, expenseId, subscriptionId, uploadedBy, imageUrl,
        status, createdAt, amount, referenceId, ocrText, reviewedBy, reviewNote,
      ];
}
