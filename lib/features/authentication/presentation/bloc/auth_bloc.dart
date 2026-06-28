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
    required UnlockWithBiometric unlockWithBiometric,
    required RestoreTrustedSession restoreTrustedSession,
    required ClearTrustedSession clearTrustedSession,
  })  : _authRepository = authRepository,
        _signInWithPhone = signInWithPhone,
        _verifyOtp = verifyOtp,
        _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple,
        _signOut = signOut,
        _unlockWithBiometric = unlockWithBiometric,
        _restoreTrustedSession = restoreTrustedSession,
        _clearTrustedSession = clearTrustedSession,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthPhoneSubmitted>(_onPhoneSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthAppleSignInRequested>(_onAppleSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthBiometricUnlockRequested>(_onBiometricUnlock);
    on<AuthBiometricBypassRequested>(_onBiometricBypass);
    on<AuthUseDifferentAccountRequested>(_onUseDifferentAccount);

    _authSubscription = _authRepository.authStateChanges.listen((_) {
      if (_sessionUnlocked) add(const AuthCheckRequested());
    });
  }

  final AuthRepository _authRepository;
  final SignInWithPhone _signInWithPhone;
  final VerifyOtp _verifyOtp;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final SignOut _signOut;
  final UnlockWithBiometric _unlockWithBiometric;
  final RestoreTrustedSession _restoreTrustedSession;
  final ClearTrustedSession _clearTrustedSession;
  StreamSubscription<dynamic>? _authSubscription;

  bool _sessionUnlocked = false;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final hasTrustedSession = await _authRepository.hasTrustedSession();

    if (hasTrustedSession && !_sessionUnlocked) {
      final biometricEnabled = await _authRepository.isBiometricEnabled();
      if (biometricEnabled) {
        final stored = await _authRepository.readTrustedUser();
        emit(AuthBiometricRequired(
          userName: stored?.name,
          phone: stored?.phone,
        ));
        return;
      }

      try {
        final user = await _authRepository.restoreTrustedSession();
        _sessionUnlocked = true;
        emit(AuthAuthenticated(user));
        return;
      } catch (_) {
        emit(const AuthUnauthenticated());
        return;
      }
    }

    final user = _authRepository.currentUser;
    if (user != null) {
      _sessionUnlocked = true;
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onPhoneSubmitted(
    AuthPhoneSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signInWithPhone(event.phoneNumber);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (verificationId) => emit(AuthOtpSent(verificationId, event.phoneNumber)),
    );
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _verifyOtp(event.verificationId, event.otp);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        _sessionUnlocked = true;
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        _sessionUnlocked = true;
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onAppleSignIn(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signInWithApple();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        _sessionUnlocked = true;
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onBiometricUnlock(
    AuthBiometricUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    final pending = state is AuthBiometricRequired
        ? state as AuthBiometricRequired
        : const AuthBiometricRequired();

    emit(AuthBiometricRequired(
      userName: pending.userName,
      phone: pending.phone,
    ));

    final result = await _unlockWithBiometric();
    result.fold(
      (failure) => emit(AuthBiometricRequired(
        userName: pending.userName,
        phone: pending.phone,
        errorMessage: failure.message,
      )),
      (user) {
        _sessionUnlocked = true;
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onBiometricBypass(
    AuthBiometricBypassRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _restoreTrustedSession();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        _sessionUnlocked = true;
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onUseDifferentAccount(
    AuthUseDifferentAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _sessionUnlocked = false;
    final result = await _clearTrustedSession();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _sessionUnlocked = false;
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
