import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthPhoneSubmitted extends AuthEvent {
  const AuthPhoneSubmitted(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthOtpSubmitted extends AuthEvent {
  const AuthOtpSubmitted(this.verificationId, this.otp);

  final String verificationId;
  final String otp;

  @override
  List<Object?> get props => [verificationId, otp];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthBiometricUnlockRequested extends AuthEvent {
  const AuthBiometricUnlockRequested();
}

class AuthUseDifferentAccountRequested extends AuthEvent {
  const AuthUseDifferentAccountRequested();
}
