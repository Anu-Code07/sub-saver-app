import 'package:equatable/equatable.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class ProfileUpdated extends ProfileState {
  const ProfileUpdated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
