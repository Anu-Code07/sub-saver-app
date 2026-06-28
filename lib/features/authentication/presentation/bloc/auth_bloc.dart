import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';
import 'package:subsaver/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_event.dart';
import 'package:subsaver/features/authentication/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required SignInWithPhone signInWithPhone,
    required VerifyOtp verifyOtp,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required SignOut signOut,
  })  : _authRepository = authRepository,
        _signInWithPhone = signInWithPhone,
        _verifyOtp = verifyOtp,
        _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple,
        _signOut = signOut,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthPhoneSubmitted>(_onPhoneSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthAppleSignInRequested>(_onAppleSignIn);
    on<AuthSignOutRequested>(_onSignOut);

    _authSubscription = _authRepository.authStateChanges.listen((_) {
      add(const AuthCheckRequested());
    });
  }

  final AuthRepository _authRepository;
  final SignInWithPhone _signInWithPhone;
  final VerifyOtp _verifyOtp;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final SignOut _signOut;
  StreamSubscription<dynamic>? _authSubscription;

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onPhoneSubmitted(AuthPhoneSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signInWithPhone(event.phoneNumber);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (verificationId) => emit(AuthOtpSent(verificationId, event.phoneNumber)),
    );
  }

  Future<void> _onOtpSubmitted(AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _verifyOtp(event.verificationId, event.otp);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onGoogleSignIn(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAppleSignIn(AuthAppleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signInWithApple();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
