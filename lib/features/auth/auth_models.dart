enum UserRole {
  admin,
  kasir;

  static UserRole fromString(String value) => switch (value) {
        'admin' => UserRole.admin,
        _ => UserRole.kasir,
      };
}

class AppProfile {
  const AppProfile({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final UserRole role;

  factory AppProfile.fromMap(Map<String, dynamic> map) => AppProfile(
        id: map['id'] as String,
        fullName: (map['full_name'] as String?) ?? '',
        role: UserRole.fromString(map['role'] as String? ?? 'kasir'),
      );

  bool get isAdmin => role == UserRole.admin;
}
