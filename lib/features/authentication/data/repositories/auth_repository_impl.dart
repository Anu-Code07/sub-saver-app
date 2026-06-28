import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/core/errors/exceptions.dart';
import 'package:subsaver/core/errors/failures.dart';
import 'package:subsaver/core/services/hive_service.dart';
import 'package:subsaver/features/authentication/data/datasources/auth_datasource.dart';
import 'package:subsaver/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:subsaver/features/authentication/data/models/user_model.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthDataSource _remote;

  @override
  Stream<UserEntity?> get authStateChanges => _remote.authStateChanges;

  @override
  UserEntity? get currentUser => _remote.currentUser;

  @override
  Future<String> signInWithPhone(String phoneNumber) async {
    try {
      return await _remote.signInWithPhone(phoneNumber);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> verifyOtp(String verificationId, String otp) async {
    try {
      return await _remote.verifyOtp(verificationId, otp);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      return await _remote.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      return await _remote.signInWithApple();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() => _remote.signOut();
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remote, this._hive);

  final UserRemoteDataSource _remote;
  final HiveService _hive;

  @override
  Future<UserEntity> getUserProfile(String uid) async {
    try {
      final user = await _remote.getUserProfile(uid);
      await _hive.cacheData(AppConstants.userBox, uid, user.toJson());
      return user;
    } on ServerException catch (e) {
      final cached = _hive.getCachedData(AppConstants.userBox, uid);
      if (cached != null) return UserModel.fromJson(cached);
      throw NotFoundFailure(e.message);
    }
  }

  @override
  Future<UserEntity> updateUserProfile(UserEntity user) async {
    try {
      final model = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        upiId: user.upiId,
        preferredPaymentMethod: user.preferredPaymentMethod,
        isPremium: user.isPremium,
        createdAt: user.createdAt,
      );
      final updated = await _remote.updateUserProfile(model);
      await _hive.cacheData(AppConstants.userBox, user.id, updated.toJson());
      return updated;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<String> uploadAvatar(String uid, String filePath) async {
    try {
      return await _remote.uploadAvatar(uid, filePath);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Stream<UserEntity> watchUserProfile(String uid) =>
      _remote.watchUserProfile(uid);
}
