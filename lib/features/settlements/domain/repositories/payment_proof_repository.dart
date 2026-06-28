import 'package:subsaver/features/settlements/domain/entities/payment_proof_entity.dart';

abstract class PaymentProofRepository {
  Future<PaymentProofEntity> uploadProof({
    required String groupId,
    required String expenseId,
    required String subscriptionId,
    required String uploadedBy,
    required String localImagePath,
    String? ocrText,
    double? amount,
    String? referenceId,
  });

  Future<List<PaymentProofEntity>> getProofsForExpense(String groupId, String expenseId);

  Future<void> reviewProof({
    required String proofId,
    required PaymentProofStatus status,
    required String reviewedBy,
    String? note,
  });
}
