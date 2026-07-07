import '../../../../core/utils/json_converters.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? message;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String?,
      link: json['link'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: parseUtcDate(json['created_at'] as String),
    );
  }
}
