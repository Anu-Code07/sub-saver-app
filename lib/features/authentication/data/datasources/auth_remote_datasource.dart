import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:subsaver/core/constants/firestore_paths.dart';
import 'package:subsaver/core/errors/exceptions.dart';
import 'package:subsaver/features/authentication/data/datasources/auth_datasource.dart';
import 'package:subsaver/features/authentication/data/models/user_model.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

class AuthRemoteDataSource implements AuthDataSource {
  AuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  String? _verificationId;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.doc(FirestorePaths.user(user.uid)).get();
        if (doc.exists) return UserModel.fromFirestore(doc);
        return UserModel(id: user.uid, name: user.displayName ?? 'User', email: user.email, phone: user.phoneNumber);
      } catch (_) {
        return UserModel(id: user.uid, name: user.displayName ?? 'User', email: user.email, phone: user.phoneNumber);
      }
    });
  }

  @override
  UserEntity? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(id: user.uid, name: user.displayName ?? 'User', email: user.email, phone: user.phoneNumber);
  }

  @override
  Future<String> signInWithPhone(String phoneNumber) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber',
      verificationCompleted: (_) {},
      verificationFailed: (e) => completer.completeError(AuthException(e.message ?? 'Verification failed')),
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
    return completer.future;
  }

  @override
  Future<UserEntity> verifyOtp(String verificationId, String otp) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId ?? verificationId,
      smsCode: otp,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) throw const AuthException('Sign in failed');
    return _ensureUserProfile(user);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw const AuthException('Google sign in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) throw const AuthException('Google sign in failed');
    return _ensureUserProfile(user);
  }

  @override
  Future<UserEntity> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final result = await _auth.signInWithCredential(oauthCredential);
    final user = result.user;
    if (user == null) throw const AuthException('Apple sign in failed');
    return _ensureUserProfile(user, appleName: appleCredential.givenName);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  @override
  void restoreSession(UserEntity user) {
    // Firebase Auth persists the session across app restarts.
  }

  Future<UserEntity> _ensureUserProfile(User firebaseUser, {String? appleName}) async {
    final docRef = _firestore.doc(FirestorePaths.user(firebaseUser.uid));
    final doc = await docRef.get();
    if (doc.exists) return UserModel.fromFirestore(doc);

    final newUser = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? appleName ?? 'User',
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
    );
    await docRef.set(newUser.toFirestore());
    return newUser;
  }
}

class UserRemoteDataSource {
  UserRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _firestore.doc(FirestorePaths.user(uid)).get();
    if (!doc.exists) throw const ServerException('User not found');
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> updateUserProfile(UserModel user) async {
    await _firestore.doc(FirestorePaths.user(user.id)).set(user.toFirestore(), SetOptions(merge: true));
    return user;
  }

  Stream<UserModel> watchUserProfile(String uid) {
    return _firestore.doc(FirestorePaths.user(uid)).snapshots().map((doc) {
      if (!doc.exists) throw const ServerException('User not found');
      return UserModel.fromFirestore(doc);
    });
  }

  Future<String> uploadAvatar(String uid, String filePath) async {
    final ref = _storage.ref().child('avatars/$uid.jpg');
    await ref.putFile(File(filePath));
    return ref.getDownloadURL();
  }
}
