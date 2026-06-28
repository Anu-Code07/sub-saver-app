import 'package:dartz/dartz.dart';
import 'package:subsaver/core/errors/failures.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';

class SignInWithPhone {
  SignInWithPhone(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, String>> call(String phoneNumber) async {
    try {
      final id = await _repository.signInWithPhone(phoneNumber);
      return Right(id);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class VerifyOtp {
  VerifyOtp(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(String verificationId, String otp) async {
    try {
      final user = await _repository.verifyOtp(verificationId, otp);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class SignInWithGoogle {
  SignInWithGoogle(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call() async {
    try {
      final user = await _repository.signInWithGoogle();
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class SignInWithApple {
  SignInWithApple(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call() async {
    try {
      final user = await _repository.signInWithApple();
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class SignOut {
  SignOut(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, void>> call() async {
    try {
      await _repository.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class UnlockWithBiometric {
  UnlockWithBiometric(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call() async {
    try {
      final user = await _repository.unlockWithBiometric();
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class ClearTrustedSession {
  ClearTrustedSession(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, void>> call() async {
    try {
      await _repository.clearTrustedSession();
      await _repository.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class RestoreTrustedSession {
  RestoreTrustedSession(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call() async {
    try {
      final user = await _repository.restoreTrustedSession();
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class GetUserProfile {
  GetUserProfile(this._repository);
  final UserRepository _repository;

  Future<Either<Failure, UserEntity>> call(String uid) async {
    try {
      final user = await _repository.getUserProfile(uid);
      return Right(user);
    } on NotFoundFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class UpdateUserProfile {
  UpdateUserProfile(this._repository);
  final UserRepository _repository;

  Future<Either<Failure, UserEntity>> call(UserEntity user) async {
    try {
      final updated = await _repository.updateUserProfile(user);
      return Right(updated);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
