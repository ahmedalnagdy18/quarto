class Room {
  final String id;
  final String name;
  final bool isOccupied;
  final DateTime? sessionStart;
  final double hourlyRate;
  final bool isVip;
  final String? psType;
  final bool? isMulti;

  Room({
    required this.id,
    required this.name,
    required this.isOccupied,
    this.sessionStart,
    required this.hourlyRate,
    this.isVip = false,
    this.psType,
    this.isMulti,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لتحليل الوقت
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toLocal();
      if (value is String) {
        try {
          return DateTime.parse(value).toLocal();
        } catch (e) {
          // print('Error parsing datetime: $value, error: $e');
          return null;
        }
      }
      return null;
    }

    return Room(
      id: json['id'].toString(),
      name: json['name'] ?? 'Room',
      isOccupied: json['is_occupied'] == true,
      sessionStart: parseDateTime(json['session_start']),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 100.0,
      isVip: json['is_vip'] == true,
      psType: json['ps_type'] as String?,
      isMulti: json['is_multi'] as bool?,
    );
  }

  // Helper method to get room type description
  String get roomTypeDescription {
    if (name.toLowerCase().contains('room 8') ||
        name.toLowerCase().contains('room8')) {
      return "Room 8 (Special)";
    }
    return isVip ? "VIP Room" : "Standard Room";
  }

  // Get display name for PS type
  String? get psTypeDisplay {
    if (psType == 'ps4') return 'PS4';
    if (psType == 'ps5') return 'PS5';
    return null;
  }

  // Get display name for session type
  String? get sessionTypeDisplay {
    if (isMulti == true) return 'Multi';
    if (isMulti == false) return 'Single';
    return null;
  }

  // تصحيح حساب المدة
  String get liveDuration {
    if (sessionStart == null) return '0h 0m';

    final now = DateTime.now();
    final start = sessionStart!;

    // التحقق من أن وقت البداية ليس في المستقبل
    if (start.isAfter(now)) {
      return '0h 0m';
    }

    final duration = now.difference(start);

    // إذا كانت المدة سلبية، نعيد صفر
    if (duration.isNegative) {
      return '0h 0m';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // تصحيح حساب التكلفة
  double get calculatedCost {
    if (sessionStart == null) return 0.0;

    final now = DateTime.now();
    final start = sessionStart!;

    // التحقق من أن وقت البداية ليس في المستقبل
    if (start.isAfter(now)) {
      return 0.0;
    }

    final duration = now.difference(start);

    // إذا كانت المدة سلبية، نعيد صفر
    if (duration.isNegative) {
      return 0.0;
    }

    final hours = duration.inMinutes / 60.0;
    final cost = (hours * hourlyRate);

    // التأكد من أن التكلفة ليست سلبية
    return cost < 0 ? 0.0 : cost;
  }

  String get formattedCurrentCost {
    return '${calculatedCost.toStringAsFixed(0)} \$';
  }
}
