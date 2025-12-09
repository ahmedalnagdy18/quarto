// lib/models/room_model.dart
class Room {
  final String id;
  final String name;
  final bool isOccupied;
  final DateTime? sessionStart;
  final double hourlyRate;

  Room({
    required this.id,
    required this.name,
    required this.isOccupied,
    this.sessionStart,
    this.hourlyRate = 100.0,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      isOccupied: json['is_occupied'] as bool,
      sessionStart: json['session_start'] != null
          ? DateTime.parse(json['session_start'] as String)
          : null,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_occupied': isOccupied,
      'session_start': sessionStart?.toIso8601String(),
      'hourly_rate': hourlyRate,
    };
  }

  // Calculate current session duration
  Duration get currentSessionDuration {
    if (sessionStart == null || !isOccupied) {
      return Duration.zero;
    }
    return DateTime.now().difference(sessionStart!);
  }

  // Calculate current cost
  double get currentSessionCost {
    final duration = currentSessionDuration;
    final hours = duration.inMinutes / 60.0;
    return hours * hourlyRate;
  }
}
