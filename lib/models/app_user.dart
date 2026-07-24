class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> roles;
  final String? bio;
  final String? photoUrl;
  final List<String> skills;
  final String? startupId;
  final bool isVerified;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roles = const [],
    this.bio,
    this.photoUrl,
    this.skills = const [],
    this.startupId,
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'roles': roles,
      'bio': bio,
      'photoUrl': photoUrl,
      'skills': skills,
      'startupId': startupId,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? (map['roles'] is List ? (map['roles'] as List).firstOrNull?.toString() ?? 'student' : 'student'),
      roles: List<String>.from(map['roles'] ?? const []),
      bio: map['bio'] as String?,
      photoUrl: map['photoUrl'] as String?,
      skills: List<String>.from(map['skills'] ?? const []),
      startupId: map['startupId'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    List<String>? roles,
    String? bio,
    String? photoUrl,
    List<String>? skills,
    String? startupId,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      skills: skills ?? this.skills,
      startupId: startupId ?? this.startupId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
