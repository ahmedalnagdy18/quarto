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
    required this.hourlyRate,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullable(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.parse(v.toString());
    }

    return Room(
      id: json['id'].toString(),
      name: json['name'] ?? 'Room',
      isOccupied: (json['is_occupied'] == true),
      sessionStart: parseNullable(json['session_start']),
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

  // ---------- helpers ----------
  Duration get currentSessionDuration {
    if (!isOccupied || sessionStart == null) return Duration.zero;
    return DateTime.now().difference(sessionStart!);
  }

  double get currentSessionCost {
    final d = currentSessionDuration;
    final hours = d.inMinutes / 60.0;
    return hours * hourlyRate;
  }

  String get sessionStartShort {
    if (sessionStart == null) return '--';
    final local = sessionStart!.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
