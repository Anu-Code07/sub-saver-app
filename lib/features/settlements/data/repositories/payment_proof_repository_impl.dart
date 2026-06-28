import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:subsaver/features/settlements/domain/entities/payment_proof_entity.dart';
import 'package:subsaver/features/settlements/domain/repositories/payment_proof_repository.dart';

class PaymentProofRepositoryImpl implements PaymentProofRepository {
  PaymentProofRepositoryImpl(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<PaymentProofEntity> uploadProof({
    required String groupId,
    required String expenseId,
    required String subscriptionId,
    required String uploadedBy,
    required String localImagePath,
    String? ocrText,
    double? amount,
    String? referenceId,
  }) async {
    final ref = _firestore.collection('paymentProofs').doc();
    final storageRef = _storage.ref('paymentProofs/${ref.id}.jpg');
    await storageRef.putFile(File(localImagePath));
    final imageUrl = await storageRef.getDownloadURL();

    final data = {
      'groupId': groupId,
      'expenseId': expenseId,
      'subscriptionId': subscriptionId,
      'uploadedBy': uploadedBy,
      'imageUrl': imageUrl,
      'status': PaymentProofStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'ocrText': ocrText,
      'amount': amount,
      'referenceId': referenceId,
    };
    await ref.set(data);

    return PaymentProofEntity(
      id: ref.id,
      groupId: groupId,
      expenseId: expenseId,
      subscriptionId: subscriptionId,
      uploadedBy: uploadedBy,
      imageUrl: imageUrl,
      status: PaymentProofStatus.pending,
      createdAt: DateTime.now(),
      ocrText: ocrText,
      amount: amount,
      referenceId: referenceId,
    );
  }

  @override
  Future<List<PaymentProofEntity>> getProofsForExpense(String groupId, String expenseId) async {
    final snap = await _firestore
        .collection('paymentProofs')
        .where('groupId', isEqualTo: groupId)
        .where('expenseId', isEqualTo: expenseId)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> reviewProof({
    required String proofId,
    required PaymentProofStatus status,
    required String reviewedBy,
    String? note,
  }) async {
    await _firestore.collection('paymentProofs').doc(proofId).update({
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewNote': note,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  PaymentProofEntity _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PaymentProofEntity(
      id: doc.id,
      groupId: d['groupId'] as String,
      expenseId: d['expenseId'] as String,
      subscriptionId: d['subscriptionId'] as String,
      uploadedBy: d['uploadedBy'] as String,
      imageUrl: d['imageUrl'] as String,
      status: PaymentProofStatus.values.byName(d['status'] as String? ?? 'pending'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (d['amount'] as num?)?.toDouble(),
      referenceId: d['referenceId'] as String?,
      ocrText: d['ocrText'] as String?,
      reviewedBy: d['reviewedBy'] as String?,
      reviewNote: d['reviewNote'] as String?,
    );
  }
}
