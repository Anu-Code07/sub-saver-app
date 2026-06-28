import 'package:equatable/equatable.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent(this.verificationId, this.phoneNumber);

  final String verificationId;
  final String phoneNumber;

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthBiometricRequired extends AuthState {
  const AuthBiometricRequired({this.userName, this.phone, this.errorMessage});

  final String? userName;
  final String? phone;
  final String? errorMessage;

  @override
  List<Object?> get props => [userName, phone, errorMessage];
}
