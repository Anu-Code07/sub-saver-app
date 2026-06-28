import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    super.email,
    super.phone,
    super.avatar,
    super.upiId,
    super.preferredPaymentMethod,
    super.isPremium,
    super.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      avatar: data['avatar'] as String?,
      upiId: data['upiId'] as String?,
      preferredPaymentMethod: data['preferredPaymentMethod'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      upiId: json['upiId'] as String?,
      preferredPaymentMethod: json['preferredPaymentMethod'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'upiId': upiId,
      'preferredPaymentMethod': preferredPaymentMethod,
      'isPremium': isPremium,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'upiId': upiId,
      'preferredPaymentMethod': preferredPaymentMethod,
      'isPremium': isPremium,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
