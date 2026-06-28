import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<String> signInWithPhone(String phoneNumber);
  Future<UserEntity> verifyOtp(String verificationId, String otp);
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> signOut();
}

abstract class UserRepository {
  Future<UserEntity> getUserProfile(String uid);
  Future<UserEntity> updateUserProfile(UserEntity user);
  Future<String> uploadAvatar(String uid, String filePath);
  Stream<UserEntity> watchUserProfile(String uid);
}
