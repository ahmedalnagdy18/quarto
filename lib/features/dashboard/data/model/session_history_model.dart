import 'package:quarto/core/extentions/app_extentions.dart';

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
    DateTime parseTime(dynamic value) {
      if (value == null) throw Exception('Null timestamp');
      if (value is DateTime) return value;
      if (value is String) {
        // تحليل الوقت من Supabase (يكون في UTC)
        final parsed = DateTime.parse(value);
        return parsed.toLocal(); // تحويل للوقت المحلي للعرض
      }
      return DateTime.parse(value.toString()).toLocal();
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

  // تنسيق وقت البداية
  String get startTimeShort {
    return TimeFormatter.formatTo12Hour(startTime);
  }

  // تنسيق وقت النهاية
  String get endTimeShort {
    if (endTime == null) return 'Running';
    return TimeFormatter.formatTo12Hour(endTime!);
  }

  String get formattedDuration {
    if (endTime == null) return 'Running';

    final duration = endTime!.difference(startTime);

    // التحقق من أن المدة غير سلبية
    if (duration.isNegative) {
      return '0m';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // تصحيح formattedCost
  String get formattedCost {
    return '${totalCost.toStringAsFixed(0)} ₪';
  }
}
