import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.upiId,
    this.preferredPaymentMethod,
    this.isPremium = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? upiId;
  final String? preferredPaymentMethod;
  final bool isPremium;
  final DateTime? createdAt;

  bool get isProfileComplete => name.isNotEmpty && name != 'User';

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? upiId,
    String? preferredPaymentMethod,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      upiId: upiId ?? this.upiId,
      preferredPaymentMethod: preferredPaymentMethod ?? this.preferredPaymentMethod,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatar,
        upiId,
        preferredPaymentMethod,
        isPremium,
        createdAt,
      ];
}
