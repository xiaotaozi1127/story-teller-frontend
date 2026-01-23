class StoryListItem {
  final String id;
  final String status;
  final String title;
  final String language;
  final int totalChunks;
  final double totalDurationSeconds;
  final String createdAt;

  StoryListItem({
    required this.id,
    required this.status,
    required this.title,
    required this.language,
    required this.totalChunks,
    required this.totalDurationSeconds,
    required this.createdAt,
  });

  factory StoryListItem.fromJson(Map<String, dynamic> json) {
    return StoryListItem(
      id: json['id'] as String,
      status: json['status'] as String,
      title: json['title'] as String? ?? 'Untitled story',
      language: json['language'] as String,
      totalChunks: _parseInteger(json['total_chunks']),
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String,
    );
  }

  static int _parseInteger(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.parse(value);
    } else if (value is num) {
      return value.toInt();
    }
    throw TypeError();
  }
}
