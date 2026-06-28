import 'dart:async';

import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/errors/exceptions.dart';
import 'package:subsaver/features/authentication/data/datasources/auth_datasource.dart';
import 'package:subsaver/features/authentication/data/models/user_model.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

class MockAuthRemoteDataSource implements AuthDataSource {
  MockAuthRemoteDataSource() {
    _controller = StreamController<UserEntity?>.broadcast(
      onListen: () => _controller.add(_user),
    );
  }

  late final StreamController<UserEntity?> _controller;
  UserEntity? _user;
  String? _pendingPhone;

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  UserEntity? get currentUser => _user;

  @override
  Future<String> signInWithPhone(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _pendingPhone = phoneNumber;
    return AppConstants.mockVerificationId;
  }

  @override
  Future<UserEntity> verifyOtp(String verificationId, String otp) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (verificationId != AppConstants.mockVerificationId) {
      throw const AuthException('Invalid verification session. Request OTP again.');
    }
    if (otp != AppConstants.mockOtpCode) {
      throw AuthException('Invalid OTP. Use ${AppConstants.mockOtpCode} in mock mode.');
    }

    final user = UserModel(
      id: 'mock-user-${_pendingPhone ?? 'demo'}',
      name: 'Demo User',
      phone: '+91${_pendingPhone ?? '9876543210'}',
      email: 'demo@subsaver.app',
      createdAt: DateTime.now(),
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _signInDemoUser('google');
  }

  @override
  Future<UserEntity> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _signInDemoUser('apple');
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _pendingPhone = null;
    _controller.add(null);
  }

  UserEntity _signInDemoUser(String provider) {
    final user = UserModel(
      id: 'mock-user-$provider',
      name: 'Demo User',
      email: 'demo@subsaver.app',
      phone: '+919876543210',
      createdAt: DateTime.now(),
    );
    _user = user;
    _controller.add(user);
    return user;
  }
}
