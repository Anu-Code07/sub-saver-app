import 'package:equatable/equatable.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class ProfileAvatarUploadRequested extends ProfileEvent {
  const ProfileAvatarUploadRequested(this.userId, this.filePath);

  final String userId;
  final String filePath;

  @override
  List<Object?> get props => [userId, filePath];
}
