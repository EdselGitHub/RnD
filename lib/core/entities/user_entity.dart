class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });
}
