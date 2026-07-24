class Opportunity {
  final String id;
  final String startupId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String commitment;
  final String stipend;
  final List<String> requiredSkills;
  final String? imageUrl;
  final bool isOpen;
  final DateTime createdAt;

  const Opportunity({
    required this.id,
    required this.startupId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.commitment,
    required this.stipend,
    this.requiredSkills = const [],
    this.imageUrl,
    this.isOpen = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startupId': startupId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'commitment': commitment,
      'stipend': stipend,
      'requiredSkills': requiredSkills,
      'imageUrl': imageUrl,
      'isOpen': isOpen,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Opportunity.fromMap(Map<String, dynamic> map) {
    return Opportunity(
      id: map['id'] as String,
      startupId: map['startupId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      location: map['location'] as String,
      commitment: map['commitment'] as String,
      stipend: map['stipend'] as String,
      requiredSkills: List<String>.from(map['requiredSkills'] ?? const []),
      imageUrl: map['imageUrl'] as String?,
      isOpen: map['isOpen'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
