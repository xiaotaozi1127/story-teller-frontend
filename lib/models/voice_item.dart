class VoiceItem {
  final String id;
  final String name;
  final String language;
  final String audioPath;
  final double durationSeconds;
  final String createdAt;

  VoiceItem({
    required this.id,
    required this.name,
    required this.language,
    required this.audioPath,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory VoiceItem.fromJson(Map<String, dynamic> json) {
    return VoiceItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed voice',
      language: json['language'] as String,
      audioPath: json['audio_path'] as String,
      durationSeconds:
          (json['duration_sec'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String,
    );
  }
}
