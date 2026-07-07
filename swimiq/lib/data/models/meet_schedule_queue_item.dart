import 'dart:convert';

/// Status of a meet-schedule photo waiting in the swimmer's queue.
enum MeetQueueStatus { queued, processing, done, error }

/// A photo of a team meet schedule uploaded for AI parsing.
class MeetScheduleQueueItem {
  const MeetScheduleQueueItem({
    required this.id,
    required this.fileName,
    required this.status,
    required this.uploadedAt,
    this.meetCount = 0,
    this.error,
  });

  final String id;
  final String fileName;
  final MeetQueueStatus status;
  final DateTime uploadedAt;
  final int meetCount;
  final String? error;

  factory MeetScheduleQueueItem.fromJson(Map<String, dynamic> json) {
    return MeetScheduleQueueItem(
      id: json['id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? 'schedule.jpg',
      status: _statusFromString(json['status'] as String?),
      uploadedAt: DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ??
          DateTime.now(),
      meetCount: (json['meet_count'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'status': status.name,
        'uploaded_at': uploadedAt.toIso8601String(),
        'meet_count': meetCount,
        if (error != null) 'error': error,
      };

  MeetScheduleQueueItem copyWith({
    MeetQueueStatus? status,
    int? meetCount,
    String? error,
    bool clearError = false,
  }) {
    return MeetScheduleQueueItem(
      id: id,
      fileName: fileName,
      status: status ?? this.status,
      uploadedAt: uploadedAt,
      meetCount: meetCount ?? this.meetCount,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static MeetQueueStatus _statusFromString(String? raw) {
    switch (raw) {
      case 'processing':
        return MeetQueueStatus.processing;
      case 'done':
        return MeetQueueStatus.done;
      case 'error':
        return MeetQueueStatus.error;
      default:
        return MeetQueueStatus.queued;
    }
  }

  static List<MeetScheduleQueueItem> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => MeetScheduleQueueItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encodeList(List<MeetScheduleQueueItem> items) {
    if (items.isEmpty) return '';
    return jsonEncode(items.map((i) => i.toJson()).toList());
  }
}
