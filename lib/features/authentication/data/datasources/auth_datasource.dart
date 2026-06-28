import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

abstract class AuthDataSource {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<String> signInWithPhone(String phoneNumber);
  Future<UserEntity> verifyOtp(String verificationId, String otp);
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> signOut();
  void restoreSession(UserEntity user);
}
