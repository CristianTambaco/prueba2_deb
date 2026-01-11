import 'package:equatable/equatable.dart';

enum UserType { adoptante, refugio }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final UserType userType;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    required this.userType,
  });

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, createdAt, userType];
}