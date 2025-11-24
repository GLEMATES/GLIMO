class UserEntity {
  final String uid;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  UserEntity copyWith({
    String? uid,
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}