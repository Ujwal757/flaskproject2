enum UserRole {
  citizen,
  authority,
  worker,
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final String passwordHash; // Hashed password
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  // Convert to database document (without password hash for security)
  Map<String, dynamic> toMap({bool includePassword = false}) {
    final map = {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
    };
    if (includePassword) {
      map['passwordHash'] = passwordHash;
    }
    return map;
  }

  // Create from database document
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.citizen,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

