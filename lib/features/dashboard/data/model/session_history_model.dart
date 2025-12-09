// lib/models/session_history.dart
class SessionHistory {
  final String id;
  final String roomId;
  final DateTime startTime;
  final DateTime? endTime;
  final double hourlyRate;
  final double totalCost;

  SessionHistory({
    required this.id,
    required this.roomId,
    required this.startTime,
    this.endTime,
    required this.hourlyRate,
    required this.totalCost,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'hourly_rate': hourlyRate,
      'total_cost': totalCost,
    };
  }

  // Calculate duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}
