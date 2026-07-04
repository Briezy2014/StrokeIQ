import '../../core/utils/supabase_parsers.dart';

class SwimVideo {
  const SwimVideo({
    this.id,
    required this.swimmer,
    required this.storagePath,
    this.title,
    this.stroke,
    this.distance,
    this.course,
    this.videoUrl,
    this.notes,
    this.createdAt,
  });

  final String? id;
  final String swimmer;
  final String storagePath;
  final String? title;
  final String? stroke;
  final String? distance;
  final String? course;
  final String? videoUrl;
  final String? notes;
  final DateTime? createdAt;

  String get swimmerName => swimmer;

  int? get distanceMeters => parseOptionalInt(distance);

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (stroke != null && distance != null) {
      return '$distance $stroke';
    }
    return 'Swim Video';
  }

  factory SwimVideo.fromJson(Map<String, dynamic> json) {
    return SwimVideo(
      id: parseUuid(json['id']),
      swimmer: swimmerFromJson(json),
      storagePath: parseOptionalText(json['storage_path']) ?? '',
      title: parseOptionalText(json['title']),
      stroke: parseOptionalText(json['stroke']),
      distance: parseOptionalText(json['distance']),
      course: parseOptionalText(json['course']),
      videoUrl: parseOptionalText(json['video_url']),
      notes: parseOptionalText(json['notes']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  factory SwimVideo.fromSupabaseRow(dynamic row) {
    return SwimVideo.fromJson(supabaseRowToMap(row));
  }

  SwimVideo copyWith({
    String? id,
    String? swimmer,
    String? storagePath,
    String? title,
    String? stroke,
    String? distance,
    String? course,
    String? videoUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return SwimVideo(
      id: id ?? this.id,
      swimmer: swimmer ?? this.swimmer,
      storagePath: storagePath ?? this.storagePath,
      title: title ?? this.title,
      stroke: stroke ?? this.stroke,
      distance: distance ?? this.distance,
      course: course ?? this.course,
      videoUrl: videoUrl ?? this.videoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'swimmer': swimmer,
        'swimmer_name': swimmer,
        'title': title,
        'stroke': stroke,
        'distance': distance?.toString(),
        'course': course,
        'storage_path': storagePath,
        'video_url': videoUrl,
        'notes': notes,
      };
}
