import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.createdAt,
    required super.userType,
  });

  factory UserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata;
    final userTypeStr = metadata?['user_type'] as String?;
    final userType = userTypeStr == 'refugio' ? UserType.refugio : UserType.adoptante;

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: metadata?['display_name'] as String?,
      photoUrl: metadata?['avatar_url'] as String?,
      createdAt: user.createdAt == null ? null : DateTime.parse(user.createdAt!),
      userType: userType,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        createdAt: createdAt,
        userType: userType,
      );
}