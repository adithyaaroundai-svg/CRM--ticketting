class CustomChannel {
  final String id;
  final String name;
  final bool isPrivate;
  final String createdBy;
  final DateTime createdAt;
  final List<String> memberIds; // Transient, fetched separately if needed

  CustomChannel({
    required this.id,
    required this.name,
    required this.isPrivate,
    required this.createdBy,
    required this.createdAt,
    this.memberIds = const [],
  });

  factory CustomChannel.fromJson(Map<String, dynamic> json) {
    return CustomChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      isPrivate: json['is_private'] as bool? ?? false,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      memberIds: (json['channel_members'] as List<dynamic>?)
              ?.map((m) => m['user_id'] as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_private': isPrivate,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
