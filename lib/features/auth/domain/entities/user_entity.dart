enum UserRole { user, helpdesk, admin }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isHelpdesk => role == UserRole.helpdesk || role == UserRole.admin;
}