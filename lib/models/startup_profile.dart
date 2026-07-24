class StartupProfile {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String sector;
  final String location;
  final String? website;
  final bool isVerified;
  final DateTime createdAt;

  const StartupProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.sector,
    required this.location,
    this.website,
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'sector': sector,
      'location': location,
      'website': website,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StartupProfile.fromMap(Map<String, dynamic> map) {
    return StartupProfile(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      sector: map['sector'] as String,
      location: map['location'] as String,
      website: map['website'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
