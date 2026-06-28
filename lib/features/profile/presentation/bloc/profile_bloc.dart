import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/features/authentication/domain/repositories/auth_repository.dart';
import 'package:subsaver/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_event.dart';
import 'package:subsaver/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required GetUserProfile getUserProfile,
    required UpdateUserProfile updateUserProfile,
    required UserRepository userRepository,
  })  : _getUserProfile = getUserProfile,
        _updateUserProfile = updateUserProfile,
        _userRepository = userRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileAvatarUploadRequested>(_onAvatarUpload);
  }

  final GetUserProfile _getUserProfile;
  final UpdateUserProfile _updateUserProfile;
  final UserRepository _userRepository;

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await _getUserProfile(event.userId);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (user) => emit(ProfileLoaded(user)),
    );
  }

  Future<void> _onUpdate(ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await _updateUserProfile(event.user);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (user) => emit(ProfileUpdated(user)),
    );
  }

  Future<void> _onAvatarUpload(ProfileAvatarUploadRequested event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final url = await _userRepository.uploadAvatar(event.userId, event.filePath);
      if (state is ProfileLoaded) {
        final current = (state as ProfileLoaded).user;
        final updated = current.copyWith(avatar: url);
        add(ProfileUpdateRequested(updated));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
