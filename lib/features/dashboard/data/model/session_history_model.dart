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
    // Supabase may return Timestamp objects or ISO strings depending on client,
    // so be defensive: if it's already a DateTime keep it, else parse string.
    DateTime parseTime(dynamic value) {
      if (value == null) throw Exception('Null timestamp');
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Supabase sometimes returns Map like {"_isUtc":..., "value":...}, but usually String.
      return DateTime.parse(value.toString());
    }

    return SessionHistory(
      id: json['id'].toString(),
      roomId: json['room_id'].toString(),
      startTime: parseTime(json['start_time']),
      endTime: json['end_time'] != null ? parseTime(json['end_time']) : null,
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

  // Duration (running if endTime == null)
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  // Short time like "14:05"
  String get startTimeShort {
    final local = startTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // If still running show 'running' or time
  String get endTimeShort {
    if (endTime == null) return 'running';
    final local = endTime!.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
