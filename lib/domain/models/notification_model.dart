/// Notification Model for GLIMO
///
/// Represents a notification that can be displayed in NotificationScreen
/// and stored in local storage (SharedPreferences)
class NotificationModel {
  final String id; // Unique ID (timestamp-based)
  final String category; // "service" or "general"
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String? payload; // Navigation target: 'monitoring', 'riwayat', etc.

  NotificationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  /// Create from JSON (for SharedPreferences)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as String?,
    );
  }

  /// Convert to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
    };
  }

  /// Create copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  /// Get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun yang lalu';
    }
  }
}
